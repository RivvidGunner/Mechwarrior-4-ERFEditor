unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, UMW4_ERF, UMW4_types, UMW4_mesh, UMW4_LOD;

type
  TfrmMain = class(TForm)
    btnOpen: TButton;
    btnSaveText: TButton;
    btnSaveERF: TButton;
    memoOutput: TMemo;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure btnOpenClick(Sender: TObject);
    procedure btnSaveTextClick(Sender: TObject);
    procedure btnSaveERFClick(Sender: TObject);
  private
    ERFObj: TERFOBj;
  public
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    ERFObj := TERFOBj.Create(OpenDialog.FileName);
    try
      memoOutput.Lines.Text := ERFObj.AsText; // Display text representation
      // Example: Modify UVs for first mesh in first LOD
      var Mesh: TMW4Mesh := ERFObj.LOD(0).Mesh(0);
      var NewUV: TAUVVertex;
      SetLength(NewUV, Mesh.NUVVertex);
      for var i := 0 to Mesh.NUVVertex - 1 do
      begin
        case i mod 4 of // Simple quad-like UV mapping
          0: NewUV[i] := P2Single(0, 0); // Top-left
          1: NewUV[i] := P2Single(1, 0); // Top-right
          2: NewUV[i] := P2Single(0, 1); // Bottom-left
          3: NewUV[i] := P2Single(1, 1); // Bottom-right
        end;
      end;
      Mesh.SetUVVertexData(NewUV);
      memoOutput.Lines.Text := ERFObj.AsText; // Update display
    except
      on E: Exception do
        ShowMessage('Error: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.btnSaveTextClick(Sender: TObject);
begin
  if SaveDialog.Execute then
    ERFObj.SaveAsText(SaveDialog.FileName);
end;

procedure TfrmMain.btnSaveERFClick(Sender: TObject);
begin
  if SaveDialog.Execute then
    ERFObj.SaveAs(SaveDialog.FileName);
end;

destructor TfrmMain.Destroy;
begin
  ERFObj.Free;
  inherited;
end;

end.