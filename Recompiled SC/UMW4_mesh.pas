unit UMW4_mesh;

interface

uses classes,sysutils,dialogs,
     tsxApi5,
     UMW4_types;

type
  TA5long   = array[1..5] of longint;
  TA255char = array[0..255] of char;

  TMW4Mesh=Class
    //Begin Data----------------------------------------------
    Lw1             :longword;         //=102
    NVertex         :longword;         //number of Vertex
    AVertex         :TAVertex;         //Vertex Array
    NUVVertex       :longword;         //number of UV Points
    aUVVertex       :TAUVVertex;       //UV Array
    TexType         :longword;         //changes for @pilot/@team,runninglights,others
    by1             :byte;             //=12
    LW01            :Integer;
    LW02            :Integer;
    SubType         :Integer;          //Texture type? 18 or 16 @team @pilor
    LW04            :Integer;
    LW05            :Integer;          //=-1
    lwTxtNameLen    :longword;         //length of texture name
    TxtName         :TA255char;
    lw3             :longword;
    nFaces3         :longword;         //number of triangles(*3) in atri
    arFaces         :TAFace;
    npla            :longword;         //number of plane equations
    apla            :TAPlane;
    lw4             :longword;
    nnorm           :longword;        //number of normals = to num of points
    anorm           :TAVertex;        // array of T3single;
    //End Data-----------------------------------------------------
    tipoMesh        :TTErfType;
    Constructor Create(_tipo:TTErfType);
    Destructor Destroy; override;
    procedure Load(fs:TFileStream);
    procedure Save(fs:TfileStream);
    procedure astext(sl:TStringList);
    Procedure SetTextureName(name:string);
    function GetTextureName:string;
    function GetSizeByte:Longword;
    //-------
    procedure SetVertexData(var avx :TAVertex);
    procedure SetUVVertexData(var auv :TAUVVertex);
    procedure SetFacesData(var af: TAFace);
    procedure UpdateNormals;
    procedure UpdatePlanes;
  End;

implementation

{ TMW4Mesh }

constructor TMW4Mesh.Create(_tipo:TTErfType);
begin
  tipoMesh := _tipo;

  //Initializations
  LW1 :=102;
  LW4 :=0;
  LW3 :=0;
end;

destructor TMW4Mesh.Destroy;
begin
  inherited Destroy;
end;

function TMW4Mesh.GetSizeByte: Longword;
var
  SizeB :Longword;
begin
  SizeB :=(15*4)+1; //static...15 longword + 1 byte
  SizeB :=SizeB+(nVertex*sizeof(T3single));
  SizeB :=SizeB+(NUVVertex*sizeof(T2single));
  SizeB :=SizeB+lwTxtNameLen+1;   //length of texture name
  if tipoMesh=weapon
     then SizeB :=SizeB+(nFaces3*sizeof(T3word))
     else SizeB :=SizeB+(nFaces3*sizeof(T3byte));
  SizeB :=SizeB+(npla*sizeof(T4single));
  SizeB :=SizeB+(nnorm*sizeof(T3single));
  GetSizeByte := SizeB;
end;

procedure TMW4Mesh.Load(fs: TFileStream);
var
  t     :integer;
  Tmp3b :T3Byte;
begin
  fs.Read(lw1,4);
  if LW1<>102 then Showmessage('Unknow version');
  
  //Load Vertex points
  fs.Read(nVertex,4);
  setlength(AVertex,nVertex);
  for t:=0 to nVertex-1
    do fs.Read(AVertex[t],sizeof(T3single));

  //Load UV points
  fs.Read(NUVVertex,sizeof(longword));
  setlength(aUVVertex,NUVVertex);
  for t:=0 to NUVVertex-1
     do fs.Read(aUVVertex[t],sizeof(T2single));

  //Texture
  fs.Read(TexType,sizeof(longword));
  fs.Read(by1,1);

  //unknow block
  fs.Read(LW01,sizeof(integer));
  fs.Read(LW02,sizeof(integer));
  fs.Read(SubType,sizeof(integer));
  fs.Read(LW04,sizeof(integer));
  fs.Read(LW05,sizeof(integer));

  //Load Texture name
  if TexType<>1
     then begin
           fs.Read(lwTxtNameLen,sizeof(longword));
           fs.Read(TxtName,lwTxtNameLen+1);
         end;
  //TxtName[lwTxtNameLen]:=#0;

  fs.Read(lw3,sizeof(longword));

  //Load Triangles data
  fs.Read(nFaces3,4);
  nFaces3:=nFaces3 div 3;

  //ERFFile.Seek(1,soFromCurrent);

  setlength(arFaces,nFaces3);
  if tipoMesh=weapon//alod[iNLOD].meshes[NMLOD].by1<>0
     then   //Faces, word format
     for t:=0 to nFaces3-1
              do fs.Read(arFaces[t],sizeof(T3word))
     else   //Faces, byte format
     for t:=0 to nFaces3-1
              do begin
                   fs.Read(Tmp3b,sizeof(Tmp3b));
                   arFaces[t].p1 :=Tmp3b.p1;
                   arFaces[t].p2 :=Tmp3b.p2;
                   arFaces[t].p3 :=Tmp3b.p3;
                 end;

  //equazioni piano d=ax+b
  //Load Plane equatios
  fs.Read(npla,4);
  setlength(apla,npla);
  for t:=0 to npla-1
      do fs.Read(apla[t],sizeof(T4single));
  fs.Read(lw4,4);

  //Load Normals
  fs.Read(nnorm,4);
  setlength(anorm,nnorm);
  for t:=0 to nnorm-1
      do fs.Read(anorm[t],sizeof(T3single));
end;

procedure TMW4Mesh.Save(fs: TfileStream);
var
  t     :integer;
  Tmp3b :T3Byte;
begin
  fs.write(lw1,4);

  //scrive vertici
  fs.Write(nVertex,4);
  for t:=0 to nVertex-1
      do fs.Write(AVertex[t],sizeof(T3single));

  //dati delle Textures
  fs.Write(NUVVertex,sizeof(longword));
  for t:=0 to NUVVertex-1
      do fs.Write(aUVVertex[t],sizeof(T2single));

  fs.Write(TexType,sizeof(longword));
  fs.Write(by1,1);
  //unknow block
  fs.Write(LW01,sizeof(integer));
  fs.Write(LW02,sizeof(integer));
  fs.Write(SubType,sizeof(integer));
  fs.Write(LW04,sizeof(integer));
  fs.Write(LW05,sizeof(integer));

  fs.Write(lwTxtNameLen,sizeof(longword));
  fs.Write(TxtName,lwTxtNameLen+1);

  fs.Write(lw3,sizeof(longword));

  //dati triangoli
  nFaces3 :=nFaces3 * 3;
  fs.Write(nFaces3,4);    //nel ERF li conta 1 per 1
  nFaces3 :=nFaces3 div 3;

  if tipoMesh=weapon
       then
       for t:=0 to nFaces3-1
                do fs.Write(arFaces[t],sizeof(T3word))
       else
       for t:=0 to nFaces3-1
                do begin
                   Tmp3b.p1:=arFaces[t].p1;
                   Tmp3b.p2:=arFaces[t].p2;
                   Tmp3b.p3:=arFaces[t].p3;
                   fs.write(Tmp3b,sizeof(Tmp3b));
                   end;

  //equazioni piano
  fs.Write(npla,4);
   for t:=0 to npla-1
      do fs.Write(apla[t],sizeof(T4single));
  fs.Write(lw4,4);

  //normali
  fs.Write(nnorm,4);
  for t:=0 to nnorm-1
      do fs.Write(anorm[t],sizeof(T3single));
end;

procedure TMW4Mesh.SetTextureName(name: string);
begin
 strpcopy(TxtName ,name);
 lwTxtNameLen:=length(name);
 if (name='@pilot') or (name='@team')
    then begin
           TexType:=16795905;  //16787713
           by1  :=12;
           LW01 :=790757375;
           LW02 :=-1;
           SubType:=18;
           LW04 :=32799;
           LW05 :=-1;
           lw3  :=0;
         end
    else  if (name='RunningLight')
         then begin
               TexType:=276848897;
               by1  :=8;
               LW01 :=790757375;
               LW02 :=-1;
               SubType:=18;
               LW04 :=33791;
               LW05 :=-1;
               lw3  :=0;
              end
         else if (name='cage1')
              then begin
                    TexType:=257;
                    by1  :=0;
                    LW01 :=792330239;
                    LW02 :=-1;
                    SubType:=29;
                    LW04 :=32799;
                    LW05 :=-1;
                    lw3  :=0;
                   end
              else if (name='isdash1')
                    then begin
                          TexType:=2305;
                          by1  :=0;
                          LW01 :=792330239;
                          LW02 :=-1;
                          SubType:=30;
                          LW04 :=32799;
                          LW05 :=-1;
                          lw3  :=0;
                         end
                    else if tipoMesh=Cage
                            then begin
                                  TexType:=4353;   //12545
                                  by1  :=32;
                                  LW01 :=792330239;
                                  LW02 :=-1;
                                  SubType:=28;
                                  LW04 :=32799;
                                  LW05 :=-1;
                                  lw3  :=0;
                                 end
                            else begin
                                  TexType:=10497;   //12545
                                  by1  :=12;
                                  LW01 :=790757375;
                                  LW02 :=-1;
                                  SubType:=16;
                                  LW04 :=32799;
                                  LW05 :=-1;
                                  lw3  :=0;
                                end;

end;

function TMW4Mesh.GetTextureName: string;
begin
  GetTextureName:=strpas(TxtName);
end;

procedure TMW4Mesh.astext(sl:TStringList);
//Procedure WriteMesh(var Mesh:TMW4Mesh;ID:integer);
  var tmpstr:string;
      t:integer;
  begin
      sl.Add('; submesh');
      sl.Add('l='+inttostr(Lw1));

      //vertici
      sl.Add(';-- Vertex data:');
      sl.Add('l='+inttostr(NVertex)+'  ; # of vertex');
      for t:=0 to nVertex-1
          do begin
             Tmpstr:='f3='+floattostr2(AVertex[t].x)+','
                      +floattostr2(AVertex[t].y)+','
                      +floattostr2(AVertex[t].z);
             sl.Add(Tmpstr);
             end;

      //textures
      sl.Add(';-- UV data');
      sl.Add('l='+inttostr(NUVVertex)+'  ; # of UV points');
      for t:=0 to nUVVertex-1
          do begin
             Tmpstr:='f2='+floattostr2(AUVVertex[t].x)+','
                      +floattostr2(AUVVertex[t].y);
             sl.Add(Tmpstr);
             end;
      //data + texture name
      sl.Add('l='+inttostr(TexType)+';   THIS NEEDS TO BE COMPUTED PROPERLY');
      sl.Add('b1='+inttostr(by1)+';');

      sl.Add('l='+inttostr(Lw01)+';');
      sl.Add('l='+inttostr(Lw02)+';');
      sl.Add('l='+inttostr(SubType)+';');
      sl.Add('l='+inttostr(Lw04)+';');
      sl.Add('l='+inttostr(Lw05)+';');
      sl.Add('z='+TxtName+';  ; TEXTURE FILE NAME');
      sl.Add('l='+inttostr(lw3)+';');

      //triangles
      sl.add('l='+inttostr(nFaces3*3)+'     ;# of triangles');
      for t:=0 to nFaces3-1
           do begin
              Tmpstr:='b3='+inttostr(arFaces[t].p1)+','
                           +inttostr(arFaces[t].p2)+','
                           +inttostr(arFaces[t].p3);
              sl.Add(Tmpstr);
              end;

      //plane equations
      sl.Add('l='+inttostr(npla));
      for t:=0 to npla-1
          do begin
             Tmpstr:='f4='+floattostr2(apla[t].x)+','
                          +floattostr2(apla[t].y)+','
                          +floattostr2(apla[t].z)+','
                          +floattostr2(apla[t].w);
             sl.Add(Tmpstr);
             end;
      sl.Add('l='+inttostr(lw4)+';');

      //point normals
      sl.Add(';    point normals');
      sl.add('l='+inttostr(nnorm));
      for t:=0 to nnorm-1
           do begin
             Tmpstr:='f3='+floattostr2(anorm[t].x)+','
                      +floattostr2(anorm[t].y)+','
                      +floattostr2(anorm[t].z);
              sl.Add(Tmpstr);
              end;
       sl.Add(';------------------------------------------------');

  end;

//procedure TERFOBj.SetDefMesh(i,n: integer);
//begin   { TODO : mettere i valori giusti }
//     aLod[i].meshes[n-1].Lw1  :=102;
//     aLod[i].meshes[n-1].lw3  :=aLod[0].meshes[0].lw3;
//     aLod[i].meshes[n-1].lw4  :=aLod[0].meshes[0].lw4;
//end;

procedure TMW4Mesh.SetVertexData(var avx: TAVertex);
var
  n :LongWord;
begin
  n:=length(avx); //high
  NVertex:=n; //+1;
  try
    setlength(AVertex,n);
    aVertex:=copy(avx);
  except
     on e:Exception do showmessage('non funzia in SetVertexData'+ e.Message);
  end;
end;

procedure TMW4Mesh.SetUVVertexData(var auv :TAUVVertex);
var
  n:integer;
begin
  n:=length(auv);    //n:=high(auv);
  NUVVertex:=n;
  try
    setlength(aUVVertex,n);
    aUVVertex:=copy(auv);
  except
    showmessage('non funzia in SetUVVertexData');
  end;
end;

procedure TMW4Mesh.SetFacesData(var af: TAFace);
var
  n:integer;
begin
  n := length(af);     //n:=high(AV);
  nFaces3:=n;
  try
    setlength(arFaces,n);
    arFaces :=copy(af);
  except
    showmessage('non funzia in SetFacesData');
  end;
end;

//copia le normali da TS - al momento non usata
//procedure TMW4Mesh.SetNormalsData(i: integer; av: TAVertex);
//var n:integer;
//    //a:Tavertex;
//begin
//     n:=high(AV);
//     aLod[CurrLOD].meshes[i].nnorm:=n+1;
//     try
//       setlength(aLod[CurrLOD].meshes[i].anorm,n);
//       aLod[CurrLOD].meshes[i].anorm :=copy(av);
//     except
//       showmessage('non funzia');
//     end;
//end;

//costruisce le normali dai vertici
procedure TMW4Mesh.UpdateNormals;
var
  t,n :integer;
begin
  n:=nVertex;
  nnorm:=n;
  setlength(anorm,n);
  for t:=0 to n-1
      do anorm[t]:=Normalize(AVertex[t]);

end;


procedure TMW4Mesh.UpdatePlanes;
var
  t,ntri :integer;
begin
  ntri:=nFaces3;
  setlength(apla,ntri);
  npla:=ntri;

  for t:=0 to ntri-1
      do apla[t]:=CalcPlaneEQ(AVertex,arFaces[t]);
end;

end.
