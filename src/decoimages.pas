{Copyright (C) 2012-2017 Yevhen Loza

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.}

{---------------------------------------------------------------------------}

{ Works with different types of images }
unit DecoImages;

{$INCLUDE compilerconfig.inc}
interface

uses Classes,
  CastleVectors, CastleGLImages, CastleImages,
  DecoInterfaceCore, DecoActor,
  DecoGlobal, DecoTime;

const InterfaceScalingMethod: TResizeInterpolation = riBilinear;  //to quickly change it. Maybe will be a variable some day to support older PCs.

type
  { General routines shared by images, frames and labels }
  DAbstractImage = class(DSingleInterfaceElement)
  protected
    { is SourceImage loaded ? }
    ImageLoaded: boolean;
    { is Image element initialized as GL image? }
    GLImage: TGLImage;
    { Is ScaledImage prepared to be initialized as GL image? }
    InitGLPending: boolean;
    { is Image ready to be drawn on screen (loaded, scaled and GL initialized) ? }
    ImageReady: boolean;
    { image loaded from a file/copied elsewhere
          in some cases (when no further scaling needed) it is freed after rescaling }
    SourceImage: TCastleImage;
    { scaled image, set to nil after GL initialized }
    ScaledImage: TCastleImage;
  public
    { initialize GL image.}
    procedure InitGL;
    { frees an image without freeing the whole instance }
    procedure FreeImage;
  public
    { non-GL part of rescaling the image }
    //function RescaleContent: boolean; override;
    { very simple draw procedure,
          checks if GL is initialized and initializes it if necessary }
    procedure Draw; override;
    procedure doDraw; virtual;
    procedure Update; override;

    constructor Create; override;
    destructor Destroy; override;
  end;

type
  { An extension to TCastleImage }
  DRectagonalFrame = class(DObject)
  public
    FrameImage: TCastleImage;
    { Frame borders }
    CornerTop, CornerBottom, CornerLeft, CornerRight: integer;
    destructor Destroy; override;
    constructor Create;
    constructor Create(const FileName: string; const cTop,cBottom,cLeft,CRight: integer);
    procedure Load(const FileName: string; const cTop,cBottom,cLeft,CRight: integer);
  end;

type
  { 3x3 scaled image (i.e. frames),
    Careful, it doesn't use SourceImage }
  DFrameImage = class(DAbstractImage)
  public
    {Reference to Frame basic image (rectagonal frame with corresponding gaps)}
    Frame: DRectagonalFrame;
    function RescaleContent: boolean; override;
    { todo: maybe not scale the image, but draw3x3 by OpenGl features? 
          or return the use of burner (e.g. noise) overlay }
  end;

type
  DFrameAnchorHelper = class helper for DAbstractElement
  public
    { Anchor this element to a DFrameImage and set all Gaps correctly }
    procedure AnchorToFrame(const aFrame: DFrameImage);
    //procedure AnchorToFrame(const aFrame: DRectagonalFrame);
  end;

type
  { Simple image rescaled by stretch
    Base for images and labels (uses RescaleImage) }
  DSimpleImage = class abstract(DAbstractImage)
  public
    function RescaleContent: boolean; override;
  end;

type
  { most simple ready-to-use image type, just a static image
      capable of loading from a file }
  DStaticImage = class(DSimpleImage)
  private
    procedure Afterload; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
  public
    { loads image in realtime }
    procedure Load(const URL: string); virtual;
    procedure Load(const CopyImage: TCastleImage); virtual;
  end;

type
  { abstract "phased image" that moves and morphs with "phase" }
  DPhasedImage = class abstract(DStaticImage)
  strict protected
    {current phases of the image}
    Phase, PhaseShift: float; //we need to store PhaseShift for override CyclePhase procedure
    procedure CyclePhase; virtual;
  public
    procedure Update; override;
  public
    { 1/seconds to scroll the full screen }
    PhaseSpeed: float;   
    procedure Load(const URL: string); override;
    procedure Load(const CopyImage: TCastleImage); override;
  end;

type
  { Wind effect used in different situations
    warning: wind images are scaled relative to Window }
  DWindImage = class(DPhasedImage)
  strict protected
    OpacityPhase: float;
    procedure CyclePhase; override;
  public
    { completely overrides the default drawing procedure }
    procedure doDraw; override;
    constructor Create; Override;
  end;

type TImageProcedure = procedure of Object;
type
  { A floating image for LoadScreens
    warning: floater images are scaled relative to Window }
  DFloatImage = class(DPhasedImage)
  strict protected
    procedure CyclePhase; override;
  public
    { Call back after one cycle is finished, usually it should call re-loading of the image }
    onCycleFinish: TImageProcedure;
    procedure doDraw; override;
    constructor Create; Override;
  end;

type TBarStyle = (bsVertical, bsHorizontal);

type
  { Generic bar used for progress bars and health bars }
  DBarImage = class(DStaticImage)
  public
    { minimmum, maximum, current maximum and current position
      minimum usually is zero and automatically set in constructor }
    Min, Max, CurrentMax, Position: float;
    { vertical or horizontal style of the bar }
    Kind: TBarStyle;
    procedure doDraw; override;
    constructor Create; override;
  end;

type
  { Bar to display health for mobs and primary 4 stats for player characters }
  DStatBarImage = class(DBarImage)
  public
    { Actor stat for display }
    Target: PStatValue;
    procedure Update; override;
  end;

{animated image}


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation
uses SysUtils, Generics.Collections, CastleFilesUtils,
  {$IFDEF BurnerImage}DecoBurner,{$ENDIF} DecoInterfaceLoader, DecoLog;

{=============================================================================}
{============================= Abstract Image ================================}
{=============================================================================}

procedure DAbstractImage.FreeImage;
begin
  FreeAndNil(GLImage);
  FreeAndNil(SourceImage);

  {BUG: I still need to free ScaledImage - while it's owned by GLImage
   DAMN IT. The link may be obsolete after FreeAndNil(GLImage)!
   Looks like I always set ScaledImage := nil after sucessfuly assigning it,
   but should keep an eye on it!}
  FreeAndNil(ScaledImage); //scaledImage is automatically freed by GlImage

  ImageReady := false;
  ImageLoaded := false;
  InitGLPending := false;
end;

{----------------------------------------------------------------------------}

procedure DAbstractImage.InitGL;
begin
  if InitGLPending then begin
    InitGLPending := false;
    if ScaledImage<>nil then begin
      FreeAndNil(GLImage);
      GLImage := TGLImage.Create(ScaledImage,true,true);
      ScaledImage := nil;
      ImageReady := true;
    end else Log(LogInterfaceGLError,{$I %CURRENTROUTINE%},'ERROR: Scaled Image is nil!');
  end;
end;

{----------------------------------------------------------------------------}

constructor DAbstractImage.Create;
begin
  inherited Create;
  InitGLPending := false;
  ImageReady := false;
  ImageLoaded := false;
end;

{----------------------------------------------------------------------------}

destructor DAbstractImage.Destroy;
begin
  FreeImage;
  inherited Destroy;
end;

{----------------------------------------------------------------------------}

procedure DAbstractImage.Update;
begin
  inherited Update;
  if GLImage <> nil then begin
    GLImage.Color := InterfaceColor;
    GLImage.Color[3] := Current.Opacity;
  end else
    Log(LogInterfaceGLError,{$I %CURRENTROUTINE%},'ERROR: GL image is nil in "update"');
end;

{----------------------------------------------------------------------------}

procedure DAbstractImage.doDraw;
begin
  GLIMage.Draw(Current.x1,Current.y1,Current.w,Current.h);
end;

{----------------------------------------------------------------------------}

procedure DAbstractImage.Draw;
begin
  //inherited Draw; //<------------ here we rewrite the draw sequence completely
  if not ImageReady then InitGL;
  if ImageReady then begin
    if not isVisible then Exit;
    Update; //Caution, Floater image might de-initialize the image in Update>CyclePhase
    {if ImageReady then // checking that in doDraw of Floater Image}
    doDraw;
  end else
    Log(LogInterfaceScaleHint,{$I %CURRENTROUTINE%},'Gl image wasn''t initialized properly');
end;

{=============================================================================}
{============================== Frame Image ==================================}
{=============================================================================}

destructor DRectagonalFrame.Destroy;
begin
  FreeAndNil(FrameImage);
  inherited Destroy;
end;

{----------------------------------------------------------------------------}

type TFrameThrash = specialize TObjectList<DRectagonalFrame>;
var FrameThrash: TFrameThrash;

constructor DRectagonalFrame.Create;
begin
  if FrameThrash = nil then FrameThrash := TFrameThrash.Create(true);
  FrameThrash.Add(Self);
end;

{----------------------------------------------------------------------------}

constructor DRectagonalFrame.Create(const FileName: string; const cTop,cBottom,cLeft,CRight: integer);
begin
  Create;
  Load(FileName, cTop,cBottom,cLeft,CRight);
end;

{----------------------------------------------------------------------------}

procedure DRectagonalFrame.Load(const FileName: string; const cTop,cBottom,cLeft,CRight: integer);
begin
  FrameImage := LoadImage(ApplicationData(FramesFolder+FileName),[TRGBAlphaImage]) as TRGBAlphaImage;
  CornerTop := cTop;
  CornerBottom := cBottom;
  CornerLeft := cLeft;
  CornerRight := cRight;
end;

{----------------------------------------------------------------------------}

function DFrameImage.RescaleContent: boolean;
var ScaledImageParts: array [0..2,0..2] of TCastleImage;
    ix, iy: integer;
    UnscaledWidth, UnscaledHeight: integer;
    SourceXs, SourceYs, DestXs, DestYs: TVector4Integer;
begin
  //inherited; <------ this procedure works completely different
  if Frame = nil then begin
    Log(LogInterfaceError,{$I %CURRENTROUTINE%},'Error: Frame is nil!');
    Exit;
  end;
  Result := true;

  ImageReady := false;
  FreeAndNil(GLImage);
  FreeAndNil(ScaledImage); //redundant, but let it be here

  SourceImage := Frame.FrameImage.CreateCopy as TRGBAlphaImage; //ugly bugfix! It's actually dangerous to just assign SourceImage to FrameImage

  ScaledImage := SourceImage.CreateCopy as TRGBAlphaImage;

  UnscaledWidth := ScaledImage.Width;
  UnscaledHeight := ScaledImage.Height;

  {check if minimal frame size is larger than the requested frame size}
  if Frame.CornerLeft+Frame.CornerRight+1 > Base.w then begin
    {$WARNING not working}
    Log(LogInterfaceScaleHint,{$I %CURRENTROUTINE%},'Reset backwards base.w = '+IntToStr(Base.w)+' / cornerLeft+cornerRight = '+IntToStr(Frame.CornerLeft+Frame.CornerRight));
    //Base.SetWidth(Frame.CornerLeft+Frame.CornerRight+1);
    Result := true;
  end;
  if Frame.CornerTop+Frame.CornerBottom+1 > Base.h then begin
    {$WARNING not working}
    Log(LogInterfaceScaleHint,{$I %CURRENTROUTINE%},'Reset backwards base.h = '+IntToStr(Base.h)+' / cornerTop+cornerBottom = '+inttostr(Frame.CornerTop+Frame.CornerBottom));
    //Base.SetHeight(Frame.CornerTop+Frame.CornerBottom+1);
    Result := true;
  end;

  SourceXs[0] := 0;
  SourceXs[1] := Frame.CornerLeft;
  SourceXs[2] := UnscaledWidth-Frame.CornerRight;
  SourceXs[3] := UnscaledWidth;
  SourceYs[0] := 0;
  SourceYs[1] := Frame.cornerBottom;
  SourceYs[2] := UnscaledHeight-Frame.CornerTop;
  SourceYs[3] := UnscaledHeight;
  DestXs[0] := 0;
  DestXs[1] := Frame.CornerLeft;
  DestXs[2] := Base.w-Frame.CornerRight;
  DestXs[3] := Base.w;
  DestYs[0] := 0;
  DestYs[1] := Frame.CornerBottom;
  DestYs[2] := Base.h-Frame.CornerTop;
  DestYs[3] := Base.h;

  for ix := 0 to 2 do
   for iy := 0 to 2 do begin
     ScaledImageParts[ix,iy] := TRGBAlphaImage.Create;
     ScaledImageParts[ix,iy].SetSize(SourceXs[ix+1]-SourceXs[ix],SourceYs[iy+1]-SourceYs[iy]);
     ScaledImageParts[ix,iy].Clear(Vector4Byte(0,0,0,0));
     ScaledImageParts[ix,iy].DrawFrom(SourceImage,0,0,SourceXs[ix],SourceYs[iy],SourceXs[ix+1]-SourceXs[ix],SourceYs[iy+1]-SourceYs[iy],dmBlendSmart);
     ScaledImageParts[ix,iy].Resize(DestXs[ix+1]-DestXs[ix],DestYs[iy+1]-DestYs[iy],riNearest);
   end;

  ScaledImage.SetSize(Base.w,Base.h,1);
  ScaledImage.Clear(Vector4byte(0,0,0,0));
  for ix := 0 to 2 do
    for iy := 0 to 2 do ScaledImage.DrawFrom(ScaledImageParts[ix,iy],DestXs[ix],DestYs[iy],0,0,DestXs[ix+1]-DestXs[ix],DestYs[iy+1]-DestYs[iy],dmBlendSmart);

  {$IFDEF BurnerImage}
  Burn(ScaledImage,Base);
  {$ENDIF}

  for ix := 0 to 2 do
    for iy := 0 to 2 do FreeAndNil(ScaledImageParts[ix,iy]);

  FreeAndNil(SourceImage); //ugly bugfix!

  InitGLPending := true;
end;

{----------------------------------------------------------------------------}

procedure DFrameAnchorHelper.AnchorToFrame(const aFrame: DFrameImage);
begin
  if aFrame = nil then begin
    Log(LogInterfaceError,{$I %CURRENTROUTINE%},'ERROR: Frame is nil!');
    Exit;
  end;
  Base.AnchorTo(aFrame.Base);
  if aFrame.Frame <> nil then begin
    Base.Anchor[asLeft].Gap := aFrame.Frame.CornerLeft;
    Base.Anchor[asRight].Gap := aFrame.Frame.CornerRight;
    Base.Anchor[asTop].Gap := aFrame.Frame.CornerTop;
    Base.Anchor[asBottom].Gap := aFrame.Frame.CornerBottom;
  end else begin
    Log(LogInterfaceError,{$I %CURRENTROUTINE%},'ERROR: Frame image is nil! Assuming zero gaps');
    Base.Anchor[asLeft].Gap := 0;
    Base.Anchor[asRight].Gap := 0;
    Base.Anchor[asTop].Gap := 0;
    Base.Anchor[asBottom].Gap := 0;
   end;
end;

{=============================================================================}
{======================== Simple image =======================================}
{=============================================================================}

function DSimpleImage.RescaleContent: boolean;
begin
 {$IFNDEF AllowRescale}
 If SourceImage = nil then begin
   Log(LogInterfaceSceleError,{$I %CURRENTROUTINE%},'Source Image is nil!');
   Exit;
 end;
 {$ENDIF}
 if ImageLoaded then begin
   if Base.isInitialized then begin
     ImageReady := false;
     FreeAndNil(GLImage);
     FreeAndNil(ScaledImage); //redundant, but let it be here
     ScaledImage := SourceImage.CreateCopy as TCastleImage;
     {$IFNDEF AllowRescale}FreeAndNil(SourceImage);{$ENDIF}
     ScaledImage.Resize(Base.w,Base.h,InterfaceScalingMethod);
     InitGLPending := true;
   end
   else
     Log(LogInterfaceScaleError,{$I %CURRENTROUTINE%},'ERROR: Base.Initialized = false');
 end;
 Result := false;
end;


{=============================================================================}
{======================== static image =======================================}
{=============================================================================}

procedure DStaticImage.Load(const URL: string);
begin
  FreeImage;
  Log(LogInitInterface,{$I %CURRENTROUTINE%},URL);
  SourceImage := LoadImage(URL);
  AfterLoad;
  Rescale;
end;
procedure DStaticImage.Load(const CopyImage: TCastleImage);
begin
  FreeImage;
  Log(LogInitInterface,{$I %CURRENTROUTINE%},'Copying image from '+CopyImage.ClassName);
  SourceImage := CopyImage.MakeCopy;
  AfterLoad;
  Rescale;
end;
procedure DStaticImage.AfterLoad;
begin
  try
    if (SourceImage = nil) or (SourceImage.IsEmpty) then raise Exception.Create('Image is not loaded!');
    Base.RealWidth := SourceImage.Width;
    Base.RealHeight := SourceImage.Height;
  except
    on E: Exception do
    begin
      Log(LogInitError,{$I %CURRENTROUTINE%},'FATAL: Image has been freed before load completed. ABORT. '{+E.Message});
      FreeImage;
      Exit;
    end;
  end;

  ImageLoaded := true;
  ImageReady := false;
end;

{=============================================================================}
{======================== phased image =======================================}
{=============================================================================}

procedure DPhasedImage.Load(const URL:string);
begin
  inherited Load(URL);
  Phase := 0;
end;
procedure DPhasedImage.Load(const CopyImage: TCastleImage);
begin
  inherited Load(CopyImage);
  Phase := 0;
end;

{----------------------------------------------------------------------------}

procedure DPhasedImage.CyclePhase;
begin
  PhaseShift := DeltaT*PhaseSpeed;
  Phase += PhaseShift*(1+0.1*drnd.Random);
end;

{----------------------------------------------------------------------------}

procedure DPhasedImage.Update;
begin
  inherited Update;
  CyclePhase;
end;

{=============================================================================}
{========================= wind image ========================================}
{=============================================================================}

constructor DWindImage.Create;
begin
  inherited Create;
  Base.AnchorToWindow := true;
  SetBaseSize(0,0,1,1,0.1);
end;

{----------------------------------------------------------------------------}

procedure DWindImage.CyclePhase;
begin
  inherited CyclePhase;
  if Phase > 1 then Phase -= 1;
  OpacityPhase += PhaseShift/2*(1+0.2*drnd.Random);
  if OpacityPhase>1 then OpacityPhase -= 1;

  if PhaseShift > 0.5 then begin
    //if pause was too long reinitialize with random phases.
    Phase := drnd.Random;
    OpacityPhase := drnd.Random;
  end;
end;

{----------------------------------------------------------------------------}

procedure DWindImage.doDraw;
var PhaseScaled:integer;
begin
  //inherited <---------- this render is different
  GLImage.Color[3] := Current.Opacity + Current.Opacity/4 * Sin(2*Pi*OpacityPhase);

  PhaseScaled := Round((1-Phase)*Window.Width);

  //draw first part of the image
  GLImage.Draw(PhaseScaled,0,
               Window.Width-PhaseScaled,Window.Height,
               0,0,
               Window.Width-PhaseScaled,Window.Height);
  //draw second part of the image
  GLImage.Draw(0,0,
               PhaseScaled,Window.Height,
               Window.Width-PhaseScaled,0,
               PhaseScaled,Window.Height);
end;

{=============================================================================}
{========================= float image =======================================}
{=============================================================================}

constructor DFloatImage.Create;
begin
  inherited Create;
  Base.AnchorToWindow := true;
  Base.ProportionalScale := psWidth;
  PhaseSpeed := 0.1;
end;

{----------------------------------------------------------------------------}

procedure DFloatImage.CyclePhase;
begin
  inherited CyclePhase;
  if Phase > 1 then begin
    Phase := 1;
    ImageLoaded := false;
    if Assigned(onCycleFinish) then onCycleFinish;
  end;
end;

{----------------------------------------------------------------------------}

procedure DFloatImage.doDraw;
var x: integer;
begin
  //inherited <---------- this render is different
  if not ImageReady then Exit; //image has been reloaded! //BUG

  GLImage.Color[3] := Current.Opacity*Sin(Pi*Phase);
  x := Round((Window.Width-Base.w)*Phase);
  GLImage.Draw(x,0);
end;

{=============================================================================}
{=========================== bar image =======================================}
{=============================================================================}

procedure DBarImage.doDraw;
var xx: integer;
begin
  //inherited <---------- this render is different
  if Max = Min then begin
    Log(LogInterfaceError,{$I %CURRENTROUTINE%},'ERROR: Division by zero!');
    Exit;
  end;
  if Kind = bsVertical then begin
    xx := Round(Base.h * Position/(Max-Min));
    GLImage.Draw(Base.x1,Base.y1,Base.w,xx);
  end else begin
    xx := Round(Base.w * Position/(Max-Min));
    GLImage.Draw(Base.x1,Base.y1,xx,Base.h);
  end;
end;

{---------------------------------------------------------------------------}

constructor DBarImage.Create;
begin
  inherited Create;
  Min := 0;
  Max := 1;
  Position := 0;
  Kind := bsHorizontal;
end;

{================ Stat Bar image =========================================}

procedure DStatBarImage.Update;
  function AboveZero(const a: float): float; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
  begin
    if a > 0 then Result := a else Result := 0;
  end;
begin
  if Target = nil then Exit; //don't waste time if target isn't present
  inherited Update;

  Min := 0;
  Max := Target^.MaxMax;
  CurrentMax := AboveZero(Target^.Max);
  Position := AboveZero(Target^.Current)
end;

finalization
FreeAndNil(FrameThrash);

end.

