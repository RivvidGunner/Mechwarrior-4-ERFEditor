unit UMW4_LOD;

interface
uses
  classes,sysutils,dialogs,
  tsxApi5,
  UMW4_types,UMW4_mesh;

Type

  TMW4LOD_Data = packed Record
      MinDist        :single;
      MaxDist        :single;
      SizeByte       :longword;          //size in bytes of LOD
      L02            :longword;          //4
      nMesh          :byte;               //+1 =5
    end;

  TMW4LOD = Class
   private
    Data       :TMW4LOD_Data ;
    MeshList   :TList;
    tipoMesh   :TTErfType;
    Ver        :LongWord;
    defTexName :String;         //default texture
    Procedure Clear;           //delete all mesh;
    Function CalcSizeByte:longword;
   public
    Constructor Create(_tipo:TTErfType;_Ver:longword);
    Destructor Destroy; override;
    procedure Load(fs:TFileStream);
    procedure Save(fs:TfileStream);
    procedure astext(sl:TStringList);
    Function GetSizeByte:longword;
    Function GetL02: longword;
    function AsTsxGNode:tsxGNode;
    Procedure SetRange(minDist, maxDist: single);
    procedure GetRange(var minDist:single; var maxDist: single);
    procedure UpdateFromTS(CurrObj:TsxGnode);
    function AddMesh:TMW4Mesh;
    procedure removeMesh(i:integer);
    Function Mesh(i:integer):TMW4Mesh;
    Function MeshCount:byte;
    procedure SetDefaultTexture(texture:string);
    Function TexturesList:string;
   end;

implementation

uses
  UMW4_TSX;

{ TMW4LOD }
//Create LOD object and related stuff
constructor TMW4LOD.Create(_tipo:TTErfType;_Ver:longword);
begin
  tipoMesh :=_tipo;
  ver      :=_Ver;
  meshList :=TList.Create;
end;

//Clear all mesh data
procedure TMW4LOD.Clear;
var
   t:integer;
begin
  for t:=0 to meshList.Count-1
      do TMW4Mesh(meshList[t]).Free;
  meshList.Clear;
  Data.nMesh:=0;
end;

//destroy LoD
Destructor TMW4LOD.Destroy;
begin
  Clear;
  meshList.Free;
  inherited destroy;
end;

//Load all the mesh of this LOD
procedure TMW4LOD.Load(fs: TFileStream);
var
  t           :integer;
  Mesh        :TMW4Mesh;
  FilePos     :LongWord;
  CurrFilePos :Longword;
begin
  Clear;
  case Ver of
    144:fs.Read(data,sizeof(Data));  // 17 bytes      //mech part
    131:begin                             //mech cage
         fs.Read(Data.SizeByte,sizeof(longword));
         fs.Read(Data.L02,sizeof(longword));
         fs.Read(Data.nMesh,sizeof(byte));
        end;
    132:begin
        end;
    145:begin
         //25byte
         fs.Seek(8,soFromCurrent);
         fs.Read(Data,sizeof(Data)); //17 bytes;
         //ERFFile.Seek(24,soFromCurrent);
         //Erffile.Read(alod[iNLOD].nMesh,sizeof(byte));
        end;
  end;

  CurrFilePos :=fs.Position;
  FilePos     :=CurrFilePos;
  //Load the mesh dada of the LOD
  for t:=0 to Data.nmesh-1
      do begin
          Mesh:=TMW4Mesh.Create(tipoMesh);
          Mesh.Load(fs);
          FilePos := Filepos + Mesh.GetSizeByte;
          if FilePos<>fs.Position then showmessage('error');
          MeshList.Add(Mesh)
         end;
end;

function TMW4LOD.Mesh(i: integer): TMW4Mesh;
begin
   Mesh:=TMW4Mesh(MeshList[i]);
end;

function TMW4LOD.MeshCount: byte;
begin
  if Data.nMesh<>MeshList.Count then showMessage('Error in MeshCount');
  MeshCount := Data.nMesh;
end;

//remoce the i mesh
procedure TMW4LOD.removeMesh(i: integer);
begin
if (i>=0) and (i<MeshList.Count-1)
   then begin
         TMW4Mesh(MeshList[i]).Free;
         MeshList.Delete(i);
         Data.nMesh := MeshList.Count;
   end;

end;

procedure TMW4LOD.Save(fs: TfileStream);
var
  t :integer;
begin
  CalcSizeByte;
  case Ver of
    144:fs.write(Data,Sizeof(Data));      //mech part
    131:begin                             //mech cage
         fs.write(Data.SizeByte,sizeof(longword));
         fs.write(Data.L02,sizeof(longword));
         fs.write(Data.nMesh,sizeof(byte));
       end;
    132:begin
        end;
  end;

  for t:=0 to Data.nmesh-1
      do TMW4Mesh(MeshList[t]).Save(fs);
end;


procedure TMW4LOD.SetDefaultTexture(texture: string);
begin
  defTexName := texture;
end;

procedure TMW4LOD.SetRange(minDist, maxDist: single);
begin
  if (MinDist>1000) or (MaxDist>1000) then showmessage(' Mindist or Maxdist >1000');
  Data.Mindist :=sqr(minDist);
  Data.Maxdist :=sqr(maxDist);
end;

function TMW4LOD.TexturesList: string;
var
  lista :string;
  txtname:string;
  t :integer;
begin
  lista :='';
  for t:= 0 to MeshList.Count-1 do
    begin
      txtname :=TMW4Mesh(MeshList.Items[t]).TxtName;
      if pos(lista,txtname) = 0
        then lista:=lista+','+txtname;
    end;
  TexturesList := lista;
end;

procedure TMW4LOD.GetRange(var minDist:single; var maxDist: single);
begin
  minDist :=sqrt(Data.Mindist);
  maxDist :=sqrt(Data.Maxdist);
end;

function TMW4LOD.GetSizeByte: longword;
begin
  GetSizeByte := Data.SizeByte;
end;

function TMW4LOD.GetL02: longword;
begin
  GetL02 := Data.L02;
end;


procedure TMW4LOD.UpdateFromTS(CurrObj: TsxGnode);
var
  MeshNum      :integer;
  ObjName      :array[0..255] of char;
  SObjName     :string;
  CurrMesh     :TMW4Mesh;

  tmpAxes      :CtsxVector3f;

    procedure Update;
    var
      textureName  :array[0..255] of char;
    begin
     CurrMesh:=addMesh;            //CurrMesh.SetLODNmesh(CurrLOD,meshnum+1);
     CurrMesh.SetVertexData(TmpAvertex);
     CurrMesh.SetUVVertexData(TmpUVVertex);
     CurrMesh.SetFacesData(TmpFaces);
     //setting normals points;
     CurrMesh.UpdateNormals;       //ERfObj.SetNormalsData(meshnum,TmpNormals);

     tsxGNodeGetName(CurrObj,ObjName,length(ObjName));
     SObjName:=Lowercase(strPas(ObjName));

     StrPcopy(TextureName,defTexName);
     if pos('pilot',SObjName)>0 then TextureName:='@pilot';
     if pos('team',SObjName)>0 then TextureName:='@team';
     if pos('cage1',SObjName)>0 then TextureName:='cage1';
     if pos('isdash1',SObjName)>0 then TextureName:='isdash1';
     if pos('runninglight',SObjName)>0
        then TextureName:='RunningLight';

     CurrMesh.SetTextureName(TextureName);
     CurrMesh.updatePlanes;
    end;

begin
   meshnum:=0;
   //setCurrLOD(nLOD);
   Clear;   //delete all mesh
   tsxGNodeGetAxesPosition(CurrObj,TmpAxes);
   if tsxSobjGetType(CurrObj)=e_tsxGROUP
      then begin
            CurrOBj:=tsxGNodeGetFirstChild(CurrObj);
            While CurrObj<>nil do
                  begin
                    createERFMesh(CurrObj,TmpAxes);
                    update;
                    inc(Meshnum);
                    CurrObj:=tsxSobjGetNext(CurrObj);
                  end;
           end
      else begin
           createERFMesh(CurrObj,TmpAxes);
           update;
           end;
   CalcSizebyte;
end;

function TMW4LOD.AddMesh: TMW4Mesh;
var
  Mesh :TMW4Mesh;
begin
   Mesh:=TMW4Mesh.Create(tipoMesh);
   MeshList.Add(Mesh);
   Data.nMesh:=MeshList.Count;
   AddMesh:=Mesh;
end;

procedure TMW4LOD.astext(sl: TStringList);
var
  t :integer;
begin
//    procedure WriteDistance;
//    begin
//         Xstr.Add('f='+floattostr2(aLod[t].MinDist)+';');
//         Xstr.Add('f='+floattostr2(aLod[t].MaxDist)+';');
//    end;
//  case Ver of
//   131:begin   //single LOD mesh
//        case ERF_HDR.LwVer of
//           1:;
//           2:;
//         end;
//      end;
//   144:begin //multiple LOD mesh
//        case ERF_HDR.LwVer of
//           5:WriteDistance;
//        end;
//       end;
//  end;


  sl.Add('l='+inttostr(Data.SizeByte)+'; Size in bytes of the LOD');
  sl.Add('l='+inttostr(Data.L02));
  sl.Add('b1='+inttostr(Data.nMesh)+'      ;    # of meshes in this LOD' );
  for t:=0 to Data.nMesh-1
    do begin
         TMW4Mesh(MeshList[t]).astext(sl);
       end;
end;

//Costruisce l'oggeto per truespace
function TMW4LOD.AsTsxGNode: tsxGNode;
var TSMeshList :TList;
    Mymesh     :tsxGnode;
    PGroup     :Pointer;
    t          :integer;
    MName      :string;
begin
  TSMeshList:=TList.Create;
  Pgroup:=nil;
  for t:=0 to Data.nMesh-1
      do begin
          Mname:='Mesh '+inttostr(t);
          Mymesh:=createTSMesh(TMW4Mesh(MeshList[t]),Mname);
          tsxPolyhInvertFaceNormals(mymesh);
          tsxSceneAddObject(Mymesh, e_tsxFALSE);
          //tsxGNodeSetRotation(Mymesh,tsxvector3f(-90,0,0));
          TSMeshList.Add(Mymesh);
          Pgroup:=MyMesh;
         end;
  for t:=0 to MeshList.Count-2
      do Pgroup:=tsxGroupAtCurrobj(TSMeshList.Items[t]);
  TSMeshList.Free;
  AsTsxGNode:=Pgroup;
end;

//calcola la dimensione in byte del un LOD
function TMW4LOD.CalcSizeByte:longword; //(t:integer):longword;
var n:integer;
    Hsize:longword;
begin
  Hsize:=5;
  for n:=0 to Data.nMesh-1
      do HSize := HSize+Mesh(n).GetSizeByte;
  Data.SizeByte := HSize;
  CalcSizeByte:=Hsize;
end;

end.
