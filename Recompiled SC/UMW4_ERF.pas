unit UMW4_ERF;  //v.2.8
//------------------------------------------------------------------------------
//unit to handle erf file format  by Scanner 2003 sscanner@hotmail.com
{

[HEADER]
[MESHES]
---------------
-HEADER-
Types
Hi: 131
        Lw: 1
            2
Hi: 141
        Lw: 2
            5
            32
            34
            37
Hi: 145
        Lw: 5
            37 

-MESHES-
[MESH]
...
[MESH]

---------------
-MESH


}
//------------------------------------------------------------------------------
interface
uses classes,sysutils,dialogs,
     tsxApi5,
     UMW4_types, UMW4_LOD, UMW4_mesh;

type

     TERF_HDR=Packed record
       HdrID1      :array[1..4] of char; //should be '#FRE'
       lw1         :longword;            //always $0E
       HiVer,LwVer :longword;            //something indicate type of mesh(cage)
     end;

     TSubHdr_145_5 = packed record
       data        :array[1..22] of byte;
     end;

     TMW4ERF_1_2 = Packed record
       TransfData  :array[1..12] of single;
       CSphere     :T4single;         //seems a sphere!!
     end;
     //*****************************************************
     TRLM_HDR=Packed record
       HdrID2      :array[1..4] of char; //should be '#RLM''
       Lw4         :longword;            //=18
     end;

     //TTErfType=(NotSup,MechPart,Cage,weapon,MapMesh);

     TERFOBj=class(Tobject)
     private
       LODList    :TList;
       defTexName :String;         //default texture
       procedure Load;
       procedure PrepareText(var Xstr:TstringList);
       //procedure PrepareERFdata(Mesh:tsxPOLYHEDRON;AxesLoc:CtsxVector3f);
       //function SizeOfaLOD(t:integer):longword;
       //Procedure SetDefMesh(i,n: integer);
     public
       fName      :string;         //filename
       ERFfile    :TFileStream;    //stream
       CurrLOD    :integer;        //current LOD
       ERF_HDR    :TERF_HDR;       //ERF Header
       MW4ERF1_2  :TMW4ERF_1_2;
       Hdr_145_5  :TSubHdr_145_5;
       NLODs      :word;           //number levels of details
       RLM_HDR    :TRLM_HDR;
       ERFType    :TTErfType;

       constructor Create(aname:string);
       destructor destroy; override;
       Function LOD(i:integer):TMW4LOD;
       Procedure ClearLODs;
       procedure DeleteLOD(i:integer);
       procedure SetLODNumber(i:integer);
       //Procedure AddLod;
       Procedure setCurrLOD(i:integer);
       //Procedure SetLODNmesh(i,n:integer);
       //Procedure UpdateUnk(i:integer);
       Procedure SetTextureName(i:integer;name:string);
       Procedure SetLODRange(i: integer; minDist, maxDist: single);
       procedure Save;
       Procedure SaveAs(aname:string);
       function AsText:string;
       Procedure SaveAsText(aname:string);
       //procedure UpdateDistances;
       function AsTsxGNode(nLOD: integer):tsxGNode;
       Procedure UpdateFromTS(nLOD:integer;CurrObj:TsxGnode);
       procedure CalcBSphere(CurrObj:TsxGnode);
       procedure SetDefaultTexture(texture:string);
       function TexturesList:string;
     end;

implementation

Uses UMW4_TSX,strutils,Math;

{ TERFMod }

constructor TERFOBJ.Create(aname: string);
begin
  fname:=aname;
  LODList :=TList.Create;
  Load;
end;

destructor TERFOBJ.destroy;
begin
  ClearLODs;
  LODList.Free;
  inherited destroy;
end;

//Set Counding Sphere data into the Header
Procedure TERFOBj.CalcBSphere(CurrObj:TsxGnode);
var
  q: T4Single;
begin
  q:=CalcolaBoundSphere(CurrObj);
  MW4ERF1_2.CSphere.X:=q.X;
  MW4ERF1_2.CSphere.Y:=q.Y;
  MW4ERF1_2.CSphere.Z:=q.Z;
  MW4ERF1_2.CSphere.W:=q.W;
end;


procedure TERFOBj.ClearLODs;
var
   t:integer;
begin
  for t:=0 to LODList.Count-1
      do LOD(t).Free;
  LODList.Clear;
  NLODs:=LODList.Count;
end;

procedure TERFOBJ.Load;
var
  NMLOD  :integer;
  t      :integer;
  TmpW   :word;
  Tmp3b  :T3Byte;
  TmpLOD :TMW4LOD;
begin
  ClearLODs;
  try
  ERFfile:=TFilestream.Create(fName,fmOpenRead);
  Erffile.Read(ERF_HDR,sizeof(ERF_HDR));
  //chech ERF type
  case ERF_HDR.HiVer of
    131:begin   //single LOD mesh
         NLODs:=1;
         case ERF_HDR.LwVer of
           1: begin             //mech cage
               ERFFile.Read(MW4ERF1_2.cSphere,sizeof(T4single));
               Erffile.Read(RLM_HDR.HdrID2,4);
               Erffile.Read(RLM_HDR.Lw4,4);
               ERFType:=Cage;
              end;
           2:begin             //weapons
               ERFFile.Seek(64,soFromCurrent);
               //ERFFile.Read(MW4ERF1_2.cSphere,sizeof(T4single));
               Erffile.Read(RLM_HDR.HdrID2,4);
               Erffile.Read(RLM_HDR.Lw4,4);
               ERFType:=Weapon;
             end;
          end;
       end;
    144:begin //multiple LOD mesh
         case ERF_HDR.LwVer of
            2:Erffile.Read(MW4ERF1_2,sizeof(MW4ERF1_2)); //mech part
            5:Erffile.Read(MW4ERF1_2.CSphere ,sizeof(T4single));
           37:Erffile.Read(MW4ERF1_2,sizeof(MW4ERF1_2));
         end;
         Erffile.Read(NLODs,2);
         Erffile.Read(RLM_HDR,sizeof(RLM_HDR));
         ERFType:=MechPart;
        end;
    //tree_alpine_sequoia02.erf
    145:begin //multiple LOD mesh
         case ERF_HDR.LwVer of
            5:begin
               ERFFile.Read(Hdr_145_5,sizeof(Hdr_145_5));
              end;
         end;
         Erffile.Read(NLODs,2);
         Erffile.Read(RLM_HDR,sizeof(RLM_HDR));
         ERFType:=MechPart;
        end;
    {132:begin     //Terreno,mappa
          case MW4ERF1.LwVer of
          1155:begin
               Erffile.Read(MW4ERF2,sizeof(MW4ERF2));
               end;
          end;
         ERFType:=MapMesh;
        end; }
    else begin
         showmessage('Sorry, not supported'+#10+inttostr(ERF_HDR.HiVer)+':'+inttostr(ERF_HDR.LwVer));;
         ERFType:=NotSup;
         exit;
         end;
  end;


  for t:=0 to NLODs-1 do
  begin
    TmpLOD :=TMW4LOD.Create(ERFType,ERF_HDR.HiVer);
    TmpLOD.Load(ERFFile);
    LODList.Add(TmpLOD)
  end;

  finally
   ERFFile.Free;
  end;
end;

procedure TERFOBJ.Save;
var
    NLOD  :integer;
    t     :integer;
    Tmp3b :T3Byte;
begin
    //setlength(aLOD,NLODs);

    ERFfile:=TFilestream.Create(fname,fmCreate);
    Erffile.write(ERF_HDR,sizeof(ERF_HDR));

    case ERF_HDR.HiVer of
         144:begin  //multiple LOD mesh
              case ERF_HDR.LwVer of
                 2:Erffile.Write(MW4ERF1_2,sizeof(MW4ERF1_2)); //mech part
                 5:Erffile.write(MW4ERF1_2.CSphere,sizeof(T4single));
                37:Erffile.write(MW4ERF1_2,sizeof(MW4ERF1_2));
              end;
              Erffile.write(NLODs,2);
              Erffile.write(RLM_HDR,sizeof(RLM_HDR));      //mech part
              ERFType:=MechPart;
             end;
         131:begin
               NLODs:=1;
               case ERF_HDR.LwVer of
                 1: begin             //mech cage
                    ERFFile.write(MW4ERF1_2.cSphere,sizeof(T4single));
                    Erffile.write(RLM_HDR.HdrID2,4);
                    Erffile.write(RLM_HDR.Lw4,4);
                    end;
                 2:begin             //weapons
                    //ERFFile.Seek(64,soFromCurrent);
                   //ERFFile.Read(MW4ERF1_2.cSphere,sizeof(T4single));
                    //Erffile.Read(MW4ERF2.HdrID2,4);
                    //Erffile.Read(MW4ERF2.Lw4,4);
                    //ERFType:=Weapon;
                   end;
              end;
            end;
         else begin
              showmessage('Sorry, I can''t save it,at moment this format is not supported');
              ERFType:=NotSup;
              exit;
              end;
    end;

    //Save the Lods
    for t:=0 to NLODs-1
        do TMW4LOD(LODList[t]).Save(Erffile);
    ERFFile.Free;
end;

procedure TERFOBj.SaveAs(aname:string);
begin
  if pos('.erf',lowercase(aname))=0 then aname:=aname+'.erf';
  fname:=aname;
  Save;
end;

function TERFOBj.LOD(i: integer): TMW4LOD;
begin
     LOD:=TMW4LOD(LODList[i]);
end;

procedure TERFOBj.DeleteLOD(i: integer);
var t:integer;
begin
  if i<=(NLODs-1)
     then begin
           LOD(i).Free;
           LODList.Delete(i);
           NLODs:=LODList.Count;
           //UpdateDistances;
          end;
end;

//delete al exceding lods, usually i = 1;
procedure TERFOBj.SetDefaultTexture(texture: string);
var
  t :integer;
begin
  defTexName := texture;
  for t:=0 to LODList.Count-1
    do LOD(t).SetDefaultTexture(texture);
end;

procedure TERFOBj.SetLODNumber(i: integer);
var
  t :integer;
begin
  for t:=LODList.Count-1 downto 0
    do if t>i-1 then DeleteLOD(t);
  NLODs:=LODList.Count;
end;

//procedure TERFOBj.AddLod;
//begin
//   inc(NLODs);
//   setlength(aLOD,NLODS);
//   aLOD[NLods-1]:=aLOD[0];
//end;


procedure TERFOBj.SetTextureName(i: integer; name: string);
begin
  if (i>=0)
      then LOD(CurrLOD).Mesh(i).SetTextureName(name);
end;


function TERFOBj.TexturesList: string;
var
  t:integer;
  Lista :string;
begin
  Lista := '';
  for t:= 0 to LodList.Count-1 do
   Lista := Lista+TMW4LOD(LodList[t]).TexturesList;
  TexturesList:=lista;
end;

//------------------------------------------------------------------------------
//salva un file erf in txt
procedure TERFOBj.PrepareText(var Xstr: TstringList);
var t:integer;
    Tmpstr:string;
    

    function sLong(l:longword;c:string):string;
    begin
         sLong:='l='+inttostr(l)+';'+StringOfChar(' ',10)+c;
    end;

    function sChar(a:array of char):string;
     var
       ret :string;
    begin
       ret :=a;
       sChar:='c'+inttostr(length(a))+'='+ret;
    end;

    procedure WriteHeaderSphere;
    begin
         Xstr.add(';    center and radius (collision sphere)');
         Xstr.Add('f='+floattostr2(MW4ERF1_2.CSphere.X));
         Xstr.Add('f='+floattostr2(MW4ERF1_2.CSphere.Y));
         Xstr.Add('f='+floattostr2(MW4ERF1_2.CSphere.Z));
         Xstr.Add('f='+floattostr2(MW4ERF1_2.CSphere.W));
    end;

    Procedure WriteHdrID2;
    begin
      Xstr.Add(sChar(RLM_HDR.HdrID2));
      Xstr.add('l='+inttostr(RLM_HDR.Lw4)+';');
    end;

    Procedure WriteMatrixData;
    begin

    end;

begin
   Xstr.clear;
   Xstr.Add(';-----------------------------------------------');
   Xstr.Add('1,'+fname);
   Xstr.Add(';-----------------------------------------------');   
   Xstr.Add(sChar(ERF_HDR.HdrID1));
   Xstr.add('l=14;');
   Xstr.add(sLong(ERF_HDR.HiVer,'Hi  ERF version number'));
   Xstr.add(sLong(ERF_HDR.LwVer,'Low ERF version number'));
   //controllo versione
   case ERF_HDR.HiVer of
         131:begin   //single LOD mesh
              case ERF_HDR.LwVer of
                 1: begin             //mech cage
                    WriteHeaderSphere;
                    WriteHdrID2;
                    //ERFType:=Cage;
                    end;
                 2:begin             //weapons
                    //ERFFile.Seek(64,soFromCurrent);
                    //ERFFile.Read(MW4ERF1_2.cSphere,sizeof(T4single));
                    //Erffile.Read(MW4ERF2.HdrID2,4);
                    //Erffile.Read(MW4ERF2.Lw4,4);
                    //ERFType:=Weapon;
                   end;
               end;
            end;
         144:begin //multiple LOD mesh
              case ERF_HDR.LwVer of
                 2:begin               //mech part
                   //ErfFile.Read(MatrixData,sizeof(single)*12);
                   WriteHeaderSphere;
                   end;
                 5:WriteHeaderSphere;
                37://Erffile.Read(MW4ERF1_2,sizeof(MW4ERF1_2));
              end;
              Xstr.add('h='+inttostr(NLODs)+'      ;    # of levels of detail');
              WriteHdrID2;
              //ERFType:=MechPart;
             end;
    end;

   for t:=0 to NLODs-1
     do begin
        Xstr.Add('; ========== LOD # '+inttostr(t)+' ==========');
        LOD(t).astext(Xstr);
        //WriteLOD(t);
        end;
end;

procedure TERFOBj.SaveAsText(aname: string);
var  Xstr:TstringList;
begin
   Xstr:=Tstringlist.create;
   PrepareText(Xstr);
   Xstr.SaveToFile(aname);
   Xstr.Free;
end;

function TERFOBj.AsText: string;
var  Xstr:TstringList;
begin
   Xstr:=Tstringlist.create;
   PrepareText(Xstr);
   AsText:=Xstr.Text;
   Xstr.Free;
end;

//------------------------------------------------------------------------------
function TERFOBj.AsTsxGNode(nLOD: integer):tsxGNode;
var MeshList :TList;
    Mymesh   :tsxGnode;
    PGroup   :Pointer;
    t        :integer;
    MName    :string;
begin
    Pgroup:=LOD(nLOD).AsTsxGNode;
    Mname:=ExtractFileName(fName);
    Mname:=replacestr(lowercase(MName),'.erf','');
    tsxGNodeSetName(Pgroup,Pchar(Mname+'-LOD '+inttostr(nLOD)));
    AsTsxGNode:=Pgroup;
end;
//------------------------------------------------------------------------------
procedure TERFOBj.UpdateFromTS(nLOD: integer;CurrObj:TsxGnode);
begin
  LOD(nLOD).UpdateFromTS(CurrObj);
end;

procedure TERFOBj.SetLODRange(i: integer; minDist, maxDist: single);
begin
    LOD(i).SetRange(minDist, maxDist);
end;

procedure TERFOBj.setCurrLOD(i: integer);
begin
    CurrLOD:=i;
end;

end.
