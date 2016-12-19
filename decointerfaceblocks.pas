{Copyright (C) 2012-2016 Yevhen Loza

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

{ Creates large interface blocks for different game situations containing
  large amounts of interface elements and composite interface elements }
unit decointerfaceblocks;

{$INCLUDE compilerconfig.inc}

interface

uses classes,
  decointerface, decointerfacecomposite,
  decoplayercharacter,
  decoglobal;


type
  {stores and displays every interface element related to current character}
  DCharacterSpace = class(DAbstractCompositeInterfaceElement)
  private
    fTarget: DPlayerCharacter;
    procedure settarget(value: DPlayerCharacter);
    procedure SlideIn(Sender: DAbstractElement; x,y: integer);
    procedure slideOut(Sender: DAbstractElement);
  public
    ID: integer;
    slided: boolean;
    StatBars: DPlayerBarsFull;
    Portrait: DPortrait;
    property Target: DPlayerCharacter read fTarget write settarget;
    procedure ArrangeChildren(animate: TAnimationStyle); override;
    constructor create(AOwner: TComponent); override;
  end;

type
  {presents 7 characters with health bars, portraits and characters control space }
  DPartyView = class (DAbstractCompositeInterfaceElement)
  public
    CharacterSpace: array [0..maxparty] of DCharacterSpace;
    procedure ArrangeChildren(animate: TAnimationStyle); override;
    constructor create(AOwner: TComponent); override;
  end;

type
  {decorations around travel screen}
  DDecorations = class(DAbstractCompositeInterfaceElement)
  private
    frame1left,frame1right,
    frame2left,frame2right,
    frame2bottomleft,frame2bottomright,
    frame3bottom : DSingleInterfaceElement;
  public
    procedure ArrangeChildren(animate: TAnimationStyle); override;
    constructor create(AOwner: TComponent); override;
  end;


{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation
//uses ;

{=============================================================================}
{=========================== Character Space =================================}
{=============================================================================}

constructor DCharacterSpace.create(AOwner: TComponent);
begin
  inherited create(AOwner);

  //create stat bars
  StatBars := DPlayerBarsFull.create(self);
  StatBars.OnMouseOver := @SlideIn;
  StatBars.OnMouseLeave := @SlideOut;
  grab(StatBars);

  //create portraits
  Portrait := DPortrait.create(self);
  grab(Portrait);

end;

{---------------------------------------------------------------------------}

procedure DCharacterSpace.ArrangeChildren(animate: TAnimationStyle);
begin
  //inherited ArrangeChildren(animate); //not needed here as this element doesn't have a frame
  {********** INTERFACE DESIGN BY Saito00 ******************}
  if odd(self.ID) then portrait.frame := portraitframe_right else
                       portrait.frame := portraitframe_left;

  if not odd(self.ID) then
    StatBars.setbasesize(10/800,-(40+155+180*(self.ID div 2))/800,35/800,155/800,1,animate)
  else
    StatBars.setbasesize(-45/800,-(40+155+180*(self.ID div 2))/800,35/800,155/800,1,animate);
  StatBars.rescale;

  if not odd(self.ID) then
    Portrait.setbasesize(47/800,-(40+155+180*(self.ID div 2))/800,135/800,155/800,1,animate)
  else
    Portrait.setbasesize(-(46+135)/800,-(40+155+180*(self.ID div 2))/800,135/800,155/800,1,animate);
  //Portrait.rescale;
  SlideOut(nil);

end;

{---------------------------------------------------------------------------}

procedure DCharacterSpace.settarget(value: DPlayerCharacter);
begin
  if fTarget <> value then begin
    self.fTarget := value;
    StatBars.Target := self.fTarget;
    Portrait.Target := self.fTarget;
  end;
end;

{---------------------------------------------------------------------------}

procedure DCharacterSpace.SlideIn(Sender: DAbstractElement; x,y: integer);
var myx: float;
begin
  if slided = false then begin
    slided := true;
    if not odd(self.ID) then
      myx := 47/800
    else
      myx := -(46)/800-Portrait.base.fw;
    Portrait.setbasesize(myx,Portrait.base.fy,Portrait.base.fw,Portrait.base.fh,1,asDefault);
    Portrait.rescale;
  end;
end;

procedure DCharacterSpace.slideOut(Sender: DAbstractElement);
var myx: float;
begin
  if slided = true then begin
    slided := false;
    if not odd(self.ID) then
      myx := 0/800
    else
      myx := -135{portrait.base.fw}/800;
    Portrait.setbasesize(myx,Portrait.base.fy,Portrait.base.fw,Portrait.base.fh,0,asDefault);
    Portrait.rescale;
  end;
end;

{---------------------------------------------------------------------------}

{=============================================================================}
{============================= Party  view ===================================}
{=============================================================================}

procedure DPartyView.ArrangeChildren(animate: TAnimationStyle);
var i: integer;
begin
  //inherited ArrangeChildren(animate); //not needed here as this element doesn't have a frame
  {********** INTERFACE DESIGN BY Saito00 ******************}

  {rescale party}
  for i := 0 to maxparty do begin
    CharacterSpace[i].setBaseSize(0,-(40+155+180*(i div 2))/800,35/800,155/800,1,animate);
//      CharacterSpace[i].setBaseSize(0,0,fullwidth,fullheight,1,animate);
  end;
end;

{-----------------------------------------------------------------------------}

constructor DPartyView.create(AOwner: TComponent);
var i: integer;
begin
  inherited Create(AOwner);
  for i := 0 to maxparty do begin
    CharacterSpace[i] := DCharacterSpace.create(self);
    CharacterSpace[i].ID := i;
    CharacterSpace[i].Target := party[i];
    grab(CharacterSpace[i]);
  end;
  setbasesize(0,0,fullwidth,fullheight,1,asNone);
//  ArrangeChildren(false); //automatically arranged on TCompositeElement.setbasesize
end;

{=============================================================================}
{============================= Decorations ===================================}
{=============================================================================}

procedure DDecorations.ArrangeChildren(animate: TAnimationStyle);
var yy1,yy2: float;
begin
  // inherited ArrangeChildren(animate); //not needed here
  {********** INTERFACE DESIGN BY Saito00 ******************}
  yy1 := (20+45+180*(maxparty div 2+1)-22)/800;
  yy2 := (20+45+180*(maxparty div 2+1)-22-27)/800;
  frame1left.       setbasesize(       0, -yy1,  50/800,   yy1, 1, asNone);
  frame2left.       setbasesize(       0,    0,   9/800, 1-yy2, 1, asNone);

  yy1 := (20+45+180*(maxparty div 2)-22)/800;
  yy2 := (20+45+180*(maxparty div 2)-22-27)/800;
  frame1right.      setbasesize( -50/800, -yy1,  50/800,   yy1, 1, asNone);
  frame2right.      setbasesize(  -9/800,    0,   9/800, 1-yy2, 1, asNone);

  frame2bottomleft. setbasesize(   9/800,    0, 300/800,  9/800, 1, asNone);
  frame2bottomright.setbasesize(-309/800,    0, 300/800,  9/800, 1, asNone);
  //todo: make frame3 scaled by content // maybe put it into a separate block?
  frame3bottom     .setbasesize( 280/800,    0, 300/800, 62/800, 1, asNone);
  frame3bottom     .base.backwardsetsize(frame2bottomright.base.x1-frame2bottomleft.base.x2+22*2,-1);
  rescale;
end;

constructor DDecorations.create(AOwner: TComponent);
begin
  inherited create(AOwner);

  frame1left := DSingleInterfaceElement.create(self);
  frame1left.frame := decorationframe1_left;
  grab(frame1left);
  frame1right := DSingleInterfaceElement.create(self);
  frame1right.frame := decorationframe1_right;
  grab(frame1right);
  frame2left := DSingleInterfaceElement.create(self);
  frame2left.frame := decorationframe2_left;
  grab(frame2left);
  frame2right := DSingleInterfaceElement.create(self);
  frame2right.frame := decorationframe2_right;
  grab(frame2right);
  frame2bottomleft := DSingleInterfaceElement.create(self);
  frame2bottomleft.frame := decorationframe2_bottomleft;
  grab(frame2bottomleft);
  frame2bottomright := DSingleInterfaceElement.create(self);
  frame2bottomright.frame := decorationframe2_bottomright;
  grab(frame2bottomright);
  frame3bottom := DSingleInterfaceElement.create(self);
  frame3bottom.frame := decorationframe3_bottom;
  grab(frame3bottom);
  setbasesize(0,0,fullwidth,fullheight,1,asNone);
end;

end.

