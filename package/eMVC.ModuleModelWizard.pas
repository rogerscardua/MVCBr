unit eMVC.ModuleModelWizard;

{ *************************************************************************** }
{ }
{ MVCBr � o resultado de esfor�os de um grupo }
{ }
{ Copyright (C) 2017 MVCBr }
{ }
{ amarildo lacerda }
{ http://www.tireideletra.com.br }
{ }
{ }
{ *************************************************************************** }
{ }
{ Licensed under the Apache License, Version 2.0 (the "License"); }
{ you may not use this file except in compliance with the License. }
{ You may obtain a copy of the License at }
{ }
{ http://www.apache.org/licenses/LICENSE-2.0 }
{ }
{ Unless required by applicable law or agreed to in writing, software }
{ distributed under the License is distributed on an "AS IS" BASIS, }
{ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{ See the License for the specific language governing permissions and }
{ limitations under the License. }
{ }
{ *************************************************************************** }

interface

{$I .\inc\Compilers.inc} // Compiler Defines

uses
  SysUtils, Windows, Controls, {$IFDEF DELPHI_5 }FileCtrl, {$ENDIF}
  System.Classes,
  eMVC.OTAUtilities,
  eMVC.projectcreator,
  eMVC.toolBox,
  eMVC.ViewCreator,
  eMVC.BaseCreator,
  eMVC.ControllerCreator,
  eMVC.ModelCreator,
  eMVC.ModuleModelCreator,
  eMVC.ModuleModelForm,
  DesignIntf,
  ToolsApi;

{$I .\translate\translate.inc}

type
  TNewMVCSetDatamoduleModelWizard = class(TNotifierObject, IOTAWizard,
    IOTARepositoryWizard, IOTAProjectWizard{$IFDEF MENUDEBUG},
    IOTAMenuWizard{$ENDIF})
  private
    FIsFMX: boolean;
    procedure SetIsFMX(const Value: boolean);
  published
    // IOTAWizard
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    // IOTARepositoryWizard
    function GetAuthor: string;
    function GetComment: string;
    function GetPage: string;
    function GetGlyph: {$IFDEF COMPILER_6_UP}Cardinal{$ELSE}HICON{$ENDIF};
{$IFDEF MENUDEBUG}
    function GetMenuText: string;
{$ENDIF}
    property IsFMX: boolean read FIsFMX write SetIsFMX;
  end;

procedure Register;

implementation

uses eMVC.ModuleModelConst, eMVC.FileCreator;

{ TNewMVCSetWizard }

{$IFDEF MENUDEBUG}

function TNewMVCSetPersistentModelWizard.GetMenuText: string;
begin
  result := '&Model MVCBr';
end;
{$ENDIF}

procedure TNewMVCSetDatamoduleModelWizard.Execute;
var
  path: string;
  project: string;
  Model: TDataModuleCreator;
  identProject: string;

  function getProjectName: string;
  var
    i: integer;
  begin
    result := GetCurrentProject.FileName;
  end;
  function GetAncestorX(idx: integer): string;
  begin
    with TStringList.create do
      try
        text := ModuleCodeAncestor;
        result := Strings[idx];
      finally
        free;
      end;
  end;
  function GetModelType(idx: integer): string;
  begin
    with TStringList.create do
      try
        text := ModuleCodeType;
        result := Strings[idx];
      finally
        free;
      end;
  end;
// %Interf
  function GetModelUses(idx: integer): string;
  begin
    with TStringList.create do
      try
        text := ModuleUses;
        result := Strings[idx];
      finally
        free;
      end;

  end;

// %modelInher
  function GetModelInher(idx: integer): string;
  begin
    with TStringList.create do
      try
        text := ModuleInherited;
        result := Strings[idx];
      finally
        free;
      end;
  end;

var
  LCriarPathModule: boolean;
  LPath:string;
  function GetNewPath(ASubPath: string): string;
  begin
    if LCriarPathModule then
      result := LPath+'\'
    else
    begin
      result := extractFilePath(project);
      if ((result + ' ')[length(result)]) <> '\' then
        result := result + '\';
      result := result + ASubPath + '\';
    end;
    if not directoryExists(result) then
      ForceDirectories(result);
  end;

begin
  project := getProjectName;
  // project := (BorlandIDEServices as IOTAModuleServices).GetActiveProject;
  if project = '' then
  begin
    eMVC.toolBox.showInfo
      (msgDontFindCreateProjectBefore);
    exit;
  end;
  path := extractFilePath(project);
  with TFormNewModuleModel.create(nil) do
  begin
    edFolder.text := extractFilePath(project)+'Models';
    if showModal = mrOK then
    begin
      IsFMX := cbFMX.Checked;
      setname := trim(edtSetname.text);
      identProject := stringReplace(setname, '.', '', [rfReplaceAll]);
      if SetNameExists(setname) then
      begin
        eMVC.toolBox.showInfo(format(msgSorryFileExists,[setname ]));
      end
      else
      begin
        LCriarPathModule := cbCreateDir.Checked;
        LPath := edFolder.text;
        if cbCreateDir.Checked then
        begin
          path := LPath + '\';
          if not directoryExists(path) then
            ForceDirectories(path);
        end;

        ChDir(extractFilePath(project));

        debug('Pronto para criar o Modulo');
        Model := TDataModuleCreator.create(GetNewPath('Models'),
          setname + '.ModuleModel', false);
        if cbFMX.Checked then
          Model.baseProjectType := bptFMX;
        // Model.SetAncestorName(GetAncestorX(ComboBox1.ItemIndex));
        Model.Templates.Add('%intf=' + ComboBox1.Items.Names
          [ComboBox1.ItemIndex]);
        Model.Templates.Add('%modelType=' + GetModelType(ComboBox1.ItemIndex));
        Model.Templates.Add('%modelName=' + GetAncestorX(ComboBox1.ItemIndex));
        Model.Templates.Add('%class=' + ComboBox1.Items.ValueFromIndex
          [ComboBox1.ItemIndex]);
        Model.Templates.Add('//%uses=' + GetModelUses(ComboBox1.ItemIndex));

        Model.Templates.Add('%interfInherited=' +
          GetModelInher(ComboBox1.ItemIndex));

        if IsFMX then
          Model.Templates.Add('*.dfm=' + '*.fmx');
        Model.Templates.Add('%UnitBase=' + setname);

        (BorlandIDEServices as IOTAModuleServices).CreateModule(Model);

        debug('Criou o Model');

        Model := TDataModuleCreator.create(GetNewPath('Models'),
          setname + '.ModuleModel', false);
        if cbFMX.Checked then
          Model.baseProjectType := bptFMX;
        // Model.SetAncestorName(GetAncestorX(ComboBox1.ItemIndex));

        Model.Templates.Add('%intf=' + ComboBox1.Items.Names
          [ComboBox1.ItemIndex]);

        Model.Templates.Add('%interfInherited=' +
          GetModelInher(ComboBox1.ItemIndex));

        Model.Templates.Add('%modelType=' + GetModelType(ComboBox1.ItemIndex));
        Model.Templates.Add('%modelName=' + GetAncestorX(ComboBox1.ItemIndex));
        Model.Templates.Add('%class=' + ComboBox1.Items.ValueFromIndex
          [ComboBox1.ItemIndex]);
        Model.Templates.Add('//%uses=' + GetModelUses(ComboBox1.ItemIndex));
        Model.Templates.Add('%UnitBase=' + setname);

        Model.isInterf := true;
        (BorlandIDEServices as IOTAModuleServices).CreateModule(Model);

        debug('Criou o Model Interf');
        ChDir(extractFilePath(project));

      end; // else
    end; // if
    free;
  end;
end;

function TNewMVCSetDatamoduleModelWizard.GetAuthor: string;
begin
  //
  // When Object Repository is in Detail mode used in the Author column
  //
  result := 'MVCBr'
end;

function TNewMVCSetDatamoduleModelWizard.GetComment: string;
begin
  //
  // When Object Repository is in Detail mode used in the Comment column
  //
  result := 'MVCBr Criar Datamodule '
end;

function TNewMVCSetDatamoduleModelWizard.GetGlyph:
{$IFDEF COMPILER_6_UP}Cardinal{$ELSE}HICON{$ENDIF};
begin
  result := LoadIcon(hInstance, 'MODULEMODEL');
end;

function TNewMVCSetDatamoduleModelWizard.GetIDString: string;
begin
  //
  // Unique name for the Wizard used internally by Delphi
  //
  result := 'MVCBr.MVCSetDataModuleModelWizard';
end;

function TNewMVCSetDatamoduleModelWizard.GetName: string;
begin
  //
  // Name used for user messages and in the Object Repository if
  // implementing a IOTARepositoryWizard object
  //
  result := '4. Datamodule';
end;

function TNewMVCSetDatamoduleModelWizard.GetPage: string;
begin
  result := 'MVCBr'
end;

function TNewMVCSetDatamoduleModelWizard.GetState: TWizardState;
begin
  //
  // For Menu Item Wizards only
  //
  result := [wsEnabled];
end;

procedure TNewMVCSetDatamoduleModelWizard.SetIsFMX(const Value: boolean);
begin
  FIsFMX := Value;
end;

procedure Register;
begin
  RegisterPackageWizard(TNewMVCSetDatamoduleModelWizard.create);

  { UnlistPublishedProperty(TModuleFactory, 'Font');
    UnlistPublishedProperty(TModuleFactory, 'ClientWidth');
    UnlistPublishedProperty(TModuleFactory, 'ClientHeight');
    UnlistPublishedProperty(TModuleFactory, 'Color');
    UnlistPublishedProperty(TModuleFactory, 'PixelsPerInch');
    UnlistPublishedProperty(TModuleFactory, 'TextHeight');
  }
end;

end.
