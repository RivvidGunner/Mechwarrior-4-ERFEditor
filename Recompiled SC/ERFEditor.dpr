program ERFEditor;

uses
  Forms,
  SysUtils,
  Dialogs,
  UMW4_ERF in 'UMW4_ERF.pas',
  UMW4_types in 'UMW4_types.pas',
  UMW4_mesh in 'UMW4_mesh.pas',
  UMW4_LOD in 'UMW4_LOD.pas',
  MainForm in 'MainForm.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.