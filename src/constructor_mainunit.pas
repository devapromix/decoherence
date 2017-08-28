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

{ Main unit which launches all other editors. DESKTOP ONLY.

  While Constructor works on internationalized data, the tool itself is
  ENGLISH ONLY. I'm not going to add any multilingual support in any future,
  Because it's a specific tool to solve specific tasks that
  while trying to keep everything simple, is a very complex thing to do
  - it's not for "all and everybody" to use. It requires knowledge of English anyway.
  If you want it - this is a FOSS project - do it yourself. But it won't be easy.}
unit constructor_mainunit;

{$INCLUDE compilerconfig.inc}
interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  fgl,
  castleLog,
  decotranslation,
  constructor_global;

type TFormList = specialize TFPGObjectList<TWriterForm>;

type
  { main form for launching other editors }
  TMainForm = class(TLanguageForm)
    PlaceholdersEditorButton: TButton;
    MapEditorButton: TButton;
    DungeonTilesEditorButton: TButton;
    SaveButton: TButton;
    CompileButton: TButton;
    FactsEditorButton: TButton;
    procedure CompileButtonClick(Sender: TObject);
    procedure DungeonTilesEditorButtonClick(Sender: TObject);
    procedure FactsEditorButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MapEditorButtonClick(Sender: TObject);
    procedure PlaceholdersEditorButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
  public
    { Generic list of all editor forms }
    AllForms: TFormList;
    { enumerates all the editor forms, fills AllForms }
    procedure MakeFormsList;
    { write the data to Architect or Game folder }
    procedure WriteMe(ToGameFolder: boolean); override;

    procedure DetectLanguageSelect; override;
  end;

var
  MainForm: TMainForm;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation
{$R *.lfm}

uses
  constructor_facts, constructor_tiles, constructor_map, constructor_placeholders;

{-----------------------------------------------------------------------------}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  //MakeFormsList;  //other forms are nil yet... so doesn't help
  MakeLanguageSwitch;
end;

{-----------------------------------------------------------------------------}

procedure TMainForm.DetectLanguageSelect;
begin
  inherited DetectLanguageSelect;
  ConstructorLanguage := MyLanguage;
end;

{-----------------------------------------------------------------------------}

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(AllForms);
end;

{-----------------------------------------------------------------------------}

procedure TMainForm.MakeFormsList;
begin
  AllForms := TFormList.create(false);
  //add all future forms here
  AllForms.Add(FactsEditor);
  AllForms.Add(DungeonTilesEditor);
  AllForms.Add(MapEditor);
  AllForms.Add(PlaceholdersEditor);
end;

{-----------------------------------------------------------------------------}

procedure TMainForm.WriteMe(ToGameFolder: boolean);
var WF: TWriterForm;
begin
  WriteLnLog('TMainForm.WriteMe','Started.');
  if AllForms = nil then MakeFormsList; //not optimal...

  for WF in AllForms do
    if not ToGameFolder then begin
      // if we're saving the constructor's own data, we save only changed data
      if WF.isLoaded {and WF.isChanged} then
        WF.WriteMe(ToGameFolder);
    end
    else begin
      // when compiling we have to save everything
      if not WF.isLoaded then WF.LoadMe;
      WF.WriteMe(ToGameFolder);
    end;
  WriteLnLog('TMainForm.WriteMe','Finished.');
end;

{-----------------------------------------------------------------------------}

procedure TMainForm.SaveButtonClick(Sender: TObject);
begin
  WriteMe(False);
end;

{-----------------------------------------------------------------------------}

procedure TMainForm.CompileButtonClick(Sender: TObject);
begin
  WriteMe(True);
end;

{---------------------------------------------------------------------------}


procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var WF: TWriterForm;
    Unsaved_data: boolean;
    Unsaved_string: string;
begin
  Unsaved_data := false;
  Unsaved_string := '';
  if AllForms = nil then MakeFormsList;

  for WF in AllForms do
    if WF.isChanged then begin
      Unsaved_data := true;
      Unsaved_string += WF.Name + ' ';
      //break;
    end;

  if unsaved_data then
    if MessageDlg('There is unsaved data in '+Unsaved_String +'! Really exit?',mtCustom, [mbYes,mbNo], 0)=MrNo then begin
      CloseAction:=canone;
      exit;
    end;
end;

{----------------------------------------------------------------------------}
{----------------------- show specific editor windows -----------------------}
{----------------------------------------------------------------------------}

procedure TMainForm.FactsEditorButtonClick(Sender: TObject);
begin
  //Application.CreateForm(TFactsEditor, FactsEditor);
  FactsEditor.Show;
end;

{----------------------------------------------------------------------------}

procedure TMainForm.DungeonTilesEditorButtonClick(Sender: TObject);
begin
  //Application.CreateForm(TDungeonTilesEditor, DungeonTilesEditor);
  DungeonTilesEditor.show;
end;

{----------------------------------------------------------------------------}

procedure TMainForm.MapEditorButtonClick(Sender: TObject);
begin
  //Application.CreateForm(TMapEditor, MapEditor);
  MapEditor.Show;
end;

{----------------------------------------------------------------------------}

procedure TMainForm.PlaceholdersEditorButtonClick(Sender: TObject);
begin
  //Application.CreateForm(TMapEditor, MapEditor);
  PlaceholdersEditor.Show;
end;


{===========================================================================}

Initialization

InitializeLog;


end.

