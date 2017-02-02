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

{ Describes groups of items containing several specific interface elements
  used in different game situations. These interface elements usually preform
  some specific function, i.e. describe specific data management elements
  in cotrast to more abstract "interface elements" which describe how elements
  are organized and displayed}
unit decointerfacecomposite;

{$INCLUDE compilerconfig.inc}

interface

uses classes,
  castleImages,
  decointerface,
  decoactor, decoplayercharacter, decoperks,
  decoglobal;


type
  { wrapper for composite Interface elements with ArrangeChildren procedure
    each child will define its own arrange method }
  DAbstractCompositeInterfaceElement = class(DInterfaceElement)
  public
    { arranges children within base.w, base.h of this container
      basically at this level it is abstract, it just substracts the frame
      from base.w and base.h and does nothing more}
    var cnt_x,cnt_y,cnt_w,cnt_h: float;
    procedure ArrangeChildren(animate: TAnimationStyle); virtual;
    { additionally calls ArrangeChildren }
    procedure setbasesize(const newx,newy,neww,newh,newo: float; animate: TAnimationStyle); override;
end;

type
  {HP,STA,CNC and MPH vertical bars for a player character}
  DPlayerBars = class(DAbstractCompositeInterfaceElement)
  private
    {these are links for easier access to the children}
    HP_bar, STA_bar, CNC_bar, MPH_bar: DSingleInterfaceElement;
    {target character}
    ftarget: DActor;
    procedure settarget(value: DActor);
  public
    {the character being monitored}
    property Target: DActor read ftarget write settarget;
    constructor create(AOwner: TComponent); override;
    procedure ArrangeChildren(animate: TAnimationStyle); override;
end;

type
  {Nickname + PlayerBars + NumericHP}
  DPlayerBarsFull = class(DAbstractCompositeInterfaceElement) //not a child of DPlayerBars!
  private
    {these are links for easier access to the children}
    PartyBars: DPlayerBars;
    NumHealth: DSingleInterfaceElement;
    NickName: DSingleInterfaceElement;
    {target character}
    ftarget: DActor;
    procedure settarget(value: DActor);
  public
    {the character being monitored}
    property Target: DActor read ftarget write settarget;
    constructor create(AOwner: TComponent); override;
    procedure ArrangeChildren(animate: TAnimationStyle); override;
  end;

type
  { character portrait. Some day it might be replaced for TUIContainer of
    the 3d character face :) Only 2D inanimated image for now... }
  DPortrait = class(DInterfaceElement)
  private
    damageoverlay: DSingleInterfaceElement;
    damagelabel: DSingleInterfaceElement;
    fTarget: DPlayerCharacter;
    procedure settarget(value: DPlayerCharacter);
  public
    {Player character which portrait is displayed}
    property Target: DPlayerCharacter read ftarget write settarget;
    constructor create(AOwner: TComponent); override;
    procedure doHit(dam: float; damtype: TDamageType);
  end;


//todo: float label is identical except pointeger -> pfloat
type
  { a simple editor for an integer variable featuring plus and minus
    buttons }
  DIntegerEdit = class(DAbstractCompositeInterfaceElement)
  private
    {sub-elements nicknames for easy access}
    iLabel: DSingleInterfaceElement;
    PlusButton, MinusButton: DSingleInterfaceElement;

    fTarget: PInteger;
    procedure settarget(value: PInteger);
  public
    {integer to change}
    property Target: Pinteger read ftarget write settarget;
    constructor create(AOwner: TComponent); override;
    procedure ArrangeChildren(animate: TAnimationStyle); override;
    procedure incTarget(Sender: DAbstractElement; x,y: integer);
    procedure decTarget(Sender: DAbstractElement; x,y: integer);
  end;

//  {integer with "bonus" edit}

type
  {A displayer for a single perk}
  DPerkInterfaceItem =  class (DInterfaceElement)
  private
    PerkImage: DSingleInterfaceElement; {animated image}
    fTarget: DPerk;
    //fCharacter: DPlayerCharacter;
    procedure settarget(value: DPerk);
    //procedure setcharacter(value: DPlayerCharacter);
  public
    property Target: DPerk read ftarget write settarget;
    //property Character: DPlayerCharacter read fCharacter write setcharacter;
    {proedure getSelectedStatus -----> update}
    constructor create(AOwner: TComponent); override;
end;

type
 {sorts in n rows and m lines the list of interface elements within self.base. Without specific data management and sorting parameters it is abstract and should parent DPerkSorter and DItemSorter}
 DAbstractSorter = class(DAbstractCompositeInterfaceElement)
   private

   public
     lines{,rows}: integer;
     procedure ArrangeChildren(animate: TAnimationStyle); override;
     constructor create(AOwner: TComponent); override;
   end;

//type TPerkContainerStyle = (pcActions,pcActive,pcGlobal);

type DPerksContainer = class(DAbstractSorter)
  {container for buffs-debuffs, perks and actions}
  private
    fTarget: DPlayerCharacter;
    procedure settarget(value: DPlayerCharacter);
  public
    //ContainerStyle: TPerkContainerStyle;
    property Target: DPlayerCharacter read ftarget write settarget;
    procedure MakePerksList(animate: TAnimationStyle);
    //procedure UpdatePerksList;
  end;




var HpBarImage, StaBarImage, CncBarImage, MphBarImage: TCastleImage; //todo not freed automatically!!!
    StatBarsFrame: DFrame;

    Portrait_img: array of TCastleImage; //todo!!!
    damageOverlay_img: TCastleImage;

    characterbar_top, characterbar_mid, characterbar_bottom,
    portraitframe_left, portraitframe_right,
    decorationframe1_left,decorationframe1_right,
    decorationframe2_left,decorationframe2_right,
    decorationframe2_bottomleft,decorationframe2_bottomright,
    decorationframe3_bottom
                                                           : DFrame;
    ActionFrame: DFrame;


{reads some interface-related data, like loading health bars images and decoration frames}
procedure InitCompositeInterface;
procedure DestroyCompositeInterface;
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

implementation
uses SysUtils, CastleLog, CastleFilesUtils, castleVectors,
   decofont, decoimages, decolabels,
   decointerfaceblocks;


procedure InitCompositeInterface;
var i: integer;
    s: string;
begin
  HpBarImage := LoadImage(ApplicationData(ProgressBarFolder+'hp_bar_CC-BY-SA_by_Saito00.png'));
  StaBarImage := LoadImage(ApplicationData(ProgressBarFolder+'en_bar_CC-BY-SA_by_Saito00.png'));
  CncBarImage := LoadImage(ApplicationData(ProgressBarFolder+'m_bar_CC-BY-SA_by_Saito00.png'));
  MphBarImage := LoadImage(ApplicationData(ProgressBarFolder+'mph_bar_CC-BY-SA_by_Saito00.png'));

  damageOverlay_img := LoadImage(ApplicationData(DamageFolder+'damageOverlay_CC0_by_EugeneLoza[GIMP].png'));

  StatBarsFrame := DFrame.create(Window);
  with StatBarsFrame do begin
    SourceImage := LoadImage(ApplicationData(FramesFolder+'blackframe.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 0; CornerBottom := 0; cornerLeft := 0; CornerRight := 1;
  end;

  setlength(portrait_img,20);
  for i := 0 to length(portrait_img)-1 do begin
    s := inttostr(i+1);
    if i+1<10 then s := '0'+s;
    Portrait_img[i] := LoadImage(ApplicationData(PortraitFolder+'UNKNOWN_p'+s+'.jpg'));
  end;
  {load artwork by Saito00}

  portraitframe_left := DFrame.create(Window);
  with portraitframe_left do begin
    SourceImage := LoadImage(ApplicationData(FramesFolder+'frameborder_left_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 4; CornerBottom := 4; cornerLeft := 3; CornerRight := 4;
  end;
  portraitframe_right := DFrame.create(Window);
  with portraitframe_right do begin
    SourceImage := LoadImage(ApplicationData(FramesFolder+'frameborder_right_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 4; CornerBottom := 4; cornerLeft := 4; CornerRight := 3;
  end;

  decorationframe1_left := DFrame.create(Window);
  with decorationframe1_left do begin
    SourceImage := LoadImage(ApplicationData(DecorationsFolder+'frame_1_left_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 3; CornerBottom := 23; cornerLeft := 2; CornerRight := 6;
  end;
  decorationframe1_right := DFrame.create(Window);
  with decorationframe1_right do begin
    SourceImage := LoadImage(ApplicationData(DecorationsFolder+'frame_1_right_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 3; CornerBottom := 23; cornerLeft := 6; CornerRight := 2;
  end;
  decorationframe2_left := DFrame.create(Window);
  with decorationframe2_left do begin
    SourceImage := LoadImage(ApplicationData(DecorationsFolder+'frame_2_left_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 6; CornerBottom := 9; cornerLeft := 2; CornerRight := 6;
  end;
  decorationframe2_right := DFrame.create(Window);
  with decorationframe2_right do begin
    SourceImage := LoadImage(ApplicationData(DecorationsFolder+'frame_2_right_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 6; CornerBottom := 9; cornerLeft := 6; CornerRight := 2;
  end;
  decorationframe2_bottomleft := DFrame.create(Window);
  with decorationframe2_bottomleft do begin
    SourceImage := LoadImage(ApplicationData(DecorationsFolder+'frame_2_bottomleft_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 6; CornerBottom := 2; cornerLeft := 0; CornerRight := 9;
  end;
  decorationframe2_bottomright := DFrame.create(Window);
  with decorationframe2_bottomright do begin
    SourceImage := LoadImage(ApplicationData(DecorationsFolder+'frame_2_bottomright_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 6; CornerBottom := 2; cornerLeft := 9; CornerRight := 0;
  end;
  decorationframe3_bottom := DFrame.create(Window);
  with decorationframe3_bottom do begin
    SourceImage := LoadImage(ApplicationData(DecorationsFolder+'frame_3_bottom_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 10; CornerBottom := 9; cornerLeft := 23; CornerRight := 23;
  end;

  characterbar_top := DFrame.create(Window);
  with characterbar_top do begin
    SourceImage := LoadImage(ApplicationData(FramesFolder+'character_bar_top_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 5; CornerBottom := 5; cornerLeft := 4; CornerRight := 4;
  end;
  characterbar_mid := DFrame.create(Window);
  with characterbar_mid do begin
    SourceImage := LoadImage(ApplicationData(FramesFolder+'character_bar_mid_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 0; CornerBottom := 0; cornerLeft := 4; CornerRight := 4;
  end;
  characterbar_bottom := DFrame.create(Window);
  with characterbar_bottom do begin
    SourceImage := LoadImage(ApplicationData(FramesFolder+'character_bar_bottom_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
    cornerTop := 5; CornerBottom := 5; cornerLeft := 4; CornerRight := 4;
  end;

  ActionFrame := DFrame.create(Window);
  ActionFrame.Rectagonal := false;
  ActionFrame.SourceImage := LoadImage(ApplicationData(FramesFolder+'action_frame_CC-BY-SA_by_Saito00.png'),[TRGBAlphaImage]) as TRGBAlphaImage;
end;

procedure DestroyCompositeInterface;
var i: integer;
begin
  writelnLog('DestroyCompositeInterface','(todo)');
  freeAndNil(HpBarImage);
  freeAndNil(StaBarImage);
  freeAndNil(CncBarImage);
  freeAndNil(MphBarImage);
  for i := 0 to length(portrait_img)-1 do
    freeAndNil(portrait_img[i]);
  setlength(portrait_img,0);
end;

{===========================================================================}

procedure DAbstractCompositeInterfaceElement.setbasesize(const newx,newy,neww,newh,newo: float; animate: TAnimationStyle);
begin
  inherited setbasesize(newx,newy,neww,newh,newo,animate);
  ArrangeChildren(animate);
end;

procedure DAbstractCompositeInterfaceElement.ArrangeChildren(animate: TAnimationStyle);
begin
  cnt_x := base.fx;
  cnt_y := base.fy;
  cnt_w := base.fw;
  cnt_h := base.fh;
  if (frame <> nil) and (frame.Rectagonal) then begin
    cnt_x += frame.cornerLeft/Window.Height;
    cnt_y += frame.cornerBottom/Window.height;
    cnt_w -= (frame.cornerLeft+frame.cornerRight)/Window.Height;
    cnt_h -= (frame.cornerTop+frame.cornerBottom)/Window.Height;
  end;



end;

{===========================================================================}
{=================== player bars ===========================================}
{===========================================================================}

constructor DPlayerBars.create(AOwner: TComponent);
var tmp_bar: DStatBarImage;
    //tmp_element: DSingleInterfaceElement;
begin
  inherited create(AOwner);
  frame := BlackFrame;

  //or make parent nil? as they are freed by freeing children? Keep an eye out for troubles...
  HP_bar := DSingleInterfaceElement.create(self);
  tmp_bar := DStatBarImage.create(HP_bar);
  tmp_bar.Load(HpBarImage);
  tmp_bar.Style := sbHealth;
  tmp_bar.Kind := bsVertical;
  HP_bar.Content := tmp_bar;
  HP_bar.frame := StatBarsFrame;
  //HP_bar.frame := SimpleFrame;
  grab(HP_bar);

  STA_bar := DSingleInterfaceElement.create(self);
  tmp_bar := DStatBarImage.create(STA_bar);
  tmp_bar.Load(StaBarImage);
  tmp_bar.Style := sbStamina;
  tmp_bar.Kind := bsVertical;
  STA_bar.frame := StatBarsFrame;
  STA_bar.Content := tmp_bar;
  //STA_bar.frame := SimpleFrame;
  grab(STA_bar);

  CNC_bar := DSingleInterfaceElement.create(self);
  tmp_bar := DStatBarImage.create(CNC_bar);
  tmp_bar.Load(CncBarImage);
  tmp_bar.Style := sbConcentration;
  tmp_bar.Kind := bsVertical;
  CNC_bar.frame := StatBarsFrame;
  CNC_bar.Content := tmp_bar;
  //STA_bar.frame := SimpleFrame;
  grab(CNC_bar);

  MPH_bar := DSingleInterfaceElement.create(self);
  tmp_bar := DStatBarImage.create(MPH_bar);
  tmp_bar.Load(MphBarImage);
  tmp_bar.Style := sbMetaphysics;
  tmp_bar.Kind := bsVertical;
  MPH_bar.frame := StatBarsFrame;
  MPH_bar.Content := tmp_bar;
  //MPH_bar.frame := SimpleFrame;
  grab(MPH_bar);
end;

{-----------------------------------------------------------------------------}

procedure DPlayerBars.settarget(value: DActor);
begin
  if ftarget <> value then begin
    ftarget := value;
    //and copy the target to all children
    (HP_bar.content as DStatBarImage).Target := ftarget;
    (STA_bar.content as DStatBarImage).Target := ftarget;
    (CNC_bar.content as DStatBarImage).Target := ftarget;
    (MPH_bar.content as DStatBarImage).Target := ftarget;
  end;
end;

{---------------------------------------------------------------------------}

procedure DPlayerBars.ArrangeChildren(animate: TAnimationStyle);
var scalex: float;
begin
  inherited ArrangeChildren(animate);

  if not base.initialized then begin
    writeLnLog('DPlayerBars.ArrangeChildren','ERROR: Base is not initialized!');
    exit;
  end;

  {metaphysics bar is displayed only if the character is known to posess metaphysic skills}
  if ftarget.maxmaxmph > 0 then scalex := cnt_w/4 else scalex := cnt_w/3;
  HP_bar. setbasesize(cnt_x         , cnt_y, scalex, cnt_h, base.opacity, animate);
  STA_bar.setbasesize(cnt_x+  scalex, cnt_y, scalex, cnt_h, base.opacity, animate);
  CNC_bar.setbasesize(cnt_x+2*scalex, cnt_y, scalex, cnt_h, base.opacity, animate);
  MPH_bar.setbasesize(cnt_x+3*scalex, cnt_y, scalex, cnt_h, base.opacity, animate);
  if ftarget.maxmaxmph > 0 then
    MPH_bar.visible := true
  else
    MPH_bar.visible := false
end;

{=============================================================================}
{================ Player bars with nickname and profession ===================}
{=============================================================================}

procedure DPlayerBarsFull.settarget(value: DActor);
begin
  if ftarget <> value then begin
    ftarget := value;
    //and copy the target to all children
    PartyBars.Target := value;
    (NumHealth.content as DFloatLabel).Value := @value.HP;
    (NickName.content as DStringLabel).Value := @value.nickname;
  end;
end;

constructor DPlayerBarsFull.create(AOwner:TComponent);
var tmp_flt: DFloatLabel;
    tmp_str: DStringLabel;
begin
  inherited create(AOwner);
  PartyBars := DPlayerBars.create(self);
  NumHealth := DSingleInterfaceElement.create(self);
  NickName  := DSingleInterfaceElement.create(self);

  PartyBars.frame := characterbar_mid;
  NickName.frame  := characterbar_top;
  NumHealth.frame := characterbar_bottom;

  tmp_flt := DFloatLabel.create(NumHealth);
  tmp_flt.Digits := 0;
  tmp_flt.ScaleLabel := true;
  tmp_flt.Font := RegularFont16;
  NumHealth.Content := tmp_flt;
  tmp_str := DStringLabel.create(NickName);
  tmp_str.ScaleLabel := true;
  tmp_str.Font := RegularFont16;
  NickName.content := tmp_str;

  grab(PartyBars);
  grab(NumHealth);
  grab(NickName);
end;

Procedure DPlayerBarsFull.ArrangeChildren(animate: TAnimationStyle);
var labelspace: float;
begin
  inherited ArrangeChildren(animate);
  {********** INTERFACE DESIGN BY Saito00 ******************}

  labelspace := 23/800;
  NickName. setbasesize(cnt_x, cnt_y+cnt_h-labelspace , cnt_w, labelspace, base.opacity, animate);
  PartyBars.setbasesize(cnt_x, cnt_y+labelspace       , cnt_w, cnt_h-2*labelspace, base.opacity, animate);
  NumHealth.setbasesize(cnt_x, cnt_y                  , cnt_w, labelspace, base.opacity, animate);
end;

{=============================================================================}
{========================== Character portrait ===============================}
{=============================================================================}

procedure DPortrait.settarget(value: DPlayerCharacter);
begin
  if ftarget <> value then begin
    ftarget := value;
    (content as DStaticImage).freeImage;
    WriteLnLog('DPortrait.settarget','Load from portrait');
    (content as DStaticImage).Load(portrait_img[rnd.random(length(portrait_img))]);  //todo
    fTarget.onHit := @self.doHit;
  end;
end;

constructor DPortrait.create(AOwner: TComponent);
var tmp_staticimage: DStaticImage;
    tmp_label: DLabel;
begin
  inherited create(AOwner);
  content := DStaticImage.create(self);
  DamageOverlay := DSingleInterfaceElement.create(self);
  tmp_staticimage := DStaticImage.create(self);
  DamageOverlay.content := tmp_staticimage;
  grab(damageOverlay);
  damageLabel := DSingleInterfaceElement.create(self);
  tmp_label := DLabel.create(self);
  tmp_label.ScaleLabel := false;
  tmp_label.Font := RegularFont16;
  damageLabel.content := tmp_label;
  grab(damageLabel);
end;

procedure DPortrait.doHit(dam: float; damtype: TDamageType);
begin
  (parent as DCharacterSpace).doSlideIn;
  (parent as DCharacterSpace).timer.settimeout(1/24/60/60);
  (damageOverlay.content as DStaticImage).FreeImage;
  case damtype of
    dtHealth: (damageOverlay.content as DStaticImage).Load(damageOverlay_img);
  end;
  damageOverlay.base.copyxywh(self.base);
  //damageOverlay.resetContentSize?
  damageOverlay.Content.base.copyxywh(self.base);
  damageOverlay.Content.AnimateTo(asFadeIn);
  damageOverlay.rescale;
  damageOverlay.AnimateTo(asFadeIn);
  if dam>0 then begin
    damageLabel.base.copyxywh(self.base);
    damageLabel.Content.base.copyxywh(self.base);
    damageLabel.AnimateTo(asFadeIn);
    damageLabel.Content.AnimateTo(asFadeIn);
    (damageLabel.content as DLabel).text := inttostr(round(dam));
    damageLabel.rescale;
  end;
end;

{=============================================================================}
{============================== Integer edit =================================}
{=============================================================================}

//range checking should be done externally by enabling/disabling the buttons.

procedure DIntegerEdit.incTarget(Sender: DAbstractElement; x,y: integer);
begin
  //remake to self.ftarget! make min/max
  {hmm... looks complex...}
  if sender is DSingleInterfaceElement then  //fool's check
    if (sender as DSingleInterfaceElement).parent is DIntegerEdit then    //another fool's check :)
      inc(((sender as DSingleInterfaceElement).parent as DIntegerEdit).Target^); //todo!!!!!!!!!
end;

procedure DIntegerEdit.decTarget(Sender: DAbstractElement; x,y: integer);
begin
  //remake to self.ftarget! make min/max
  {hmm... looks complex...}
  if sender is DSingleInterfaceElement then  //fool's check
    if (sender as DSingleInterfaceElement).parent is DIntegerEdit then    //another fool's check :)
      dec(((sender as DSingleInterfaceElement).parent as DIntegerEdit).Target^); //todo!!!!!!!!!
end;

{---------------------------------------------------------------------------}

constructor DIntegerEdit.create(AOwner: TComponent);
var tmp: DIntegerLabel;
    tmpimg: DStaticImage;
begin
  inherited create(AOwner);
  ilabel := DSingleInterfaceElement.create(self);
  tmp := DIntegerLabel.create(ilabel);
  ilabel.content := tmp;
  //ilabel.frame := simpleframe;
  grab(ilabel);

  PlusButton := DSingleInterfaceElement.create(self);
  //PlusButton.parent
  PlusButton.CanMouseOver := true;
  PlusButton.OnMousePress := @IncTarget;
  tmpImg := DStaticImage.create(PlusButton);
  //tmpImg.LoadThread('');
  PlusButton.content := tmpImg;
  grab(PlusButton);

  MinusButton := DSingleInterfaceElement.create(self);
  MinusButton.CanMouseOver := true;
  MinusButton.OnMousePress := @decTarget;
  tmpImg := DStaticImage.create(MinusButton);
  //tmpImg.LoadThread('');
  MinusButton.content := tmpImg;
  grab(MinusButton);
end;

{---------------------------------------------------------------------------}

procedure DIntegerEdit.settarget(value: pinteger);
begin
  if ftarget <> value then begin
    ftarget := value;
    (ilabel.content as DIntegerLabel).value := value;
    //reset button activity
  end;
end;

{---------------------------------------------------------------------------}

procedure DIntegerEdit.ArrangeChildren(animate: TAnimationStyle);
begin
  inherited ArrangeChildren(animate);
  //todo ***
  PlusButton.setbasesize(cnt_x,cnt_y,cnt_h,cnt_h,1,animate);
  MinusButton.setbasesize(cnt_x+cnt_w-cnt_h,cnt_y,cnt_h,cnt_h,1,animate);
  iLabel.setbasesize(cnt_x+cnt_h,cnt_y,cnt_w-2*cnt_h,cnt_h,1,animate);
end;

{=============================================================================}
{=========================== Perks container =================================}
{=============================================================================}

procedure DPerkInterfaceItem.settarget(value: DPerk);
begin
  if value <> fTarget then begin
    fTarget := value;
    (PerkImage.content as DStaticImage).FreeImage;
    (PerkImage.content as DStaticImage).load(fTarget.Image.SourceImage);
    //add events?
  end;
end;

constructor DPerkInterfaceItem.create(AOwner: TComponent);
var tmp: DStaticImage;
begin
  inherited create(AOwner);
  PerkImage := DSingleInterfaceElement.create(self);
  tmp := DStaticImage.create(self);
  PerkImage.Content := tmp;
  grab(PerkImage);
end;

{=============================================================================}
{=========================== Abstract sorter =================================}
{=============================================================================}

procedure DAbstractSorter.ArrangeChildren(animate: TAnimationStyle);
var scale: float;
    i: integer;
begin
  inherited ArrangeChildren(animate);
  scale := cnt_h/lines;
  for i := 0 to children.Count-1 do children[i].setbasesize(cnt_x+i*scale,cnt_y,scale,scale,1,animate);
  //todo : auto scrollers
end;

{---------------------------------------------------------------------}

constructor DAbstractSorter.create(AOwner: TComponent);
begin
  inherited create(AOwner);
  Lines := 1;
end;

{=============================================================================}
{=========================== Perks container =================================}
{=============================================================================}


procedure DPerksContainer.settarget(value: DPlayerCharacter);
begin
  if ftarget <> value then begin
    ftarget := value;
    MakePerksList(asNone);
  end;
end;

{---------------------------------------------------------------------}

procedure DPerksContainer.MakePerksList(animate: TAnimationStyle);
var tmp: DSingleInterfaceElement;
    i: integer;
begin
  if fTarget<>nil then begin
    if (fTarget.Actions<>nil) and (fTarget.Actions.count>0) then begin
      children.Clear;
      for i:= 0 to fTarget.Actions.count-1 do begin
        tmp := DSingleInterfaceElement.create(self);
        tmp.Content := DStaticImage.create(tmp);
        (tmp.Content as DSTaticImage).Load(fTarget.Actions[0].Image.SourceImage);
        grab(tmp);
      end;
      ArrangeChildren(animate);
    end else
      WriteLnLog('DPerksContainer.MakePerksList','ERROR: Target.Actions is empty!');
  end else
    WriteLnLog('DPerksContainer.MakePerksList','ERROR: Target is nil!');
end;

{---------------------------------------------------------------------}

end.

