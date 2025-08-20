{-----------------------------------------------------------------------------
 Unit Name: UMW4_types
 Author:    RISC
 Purpose:   contiene i tipi base usati per gestire i dati
 History:
-----------------------------------------------------------------------------}

unit UMW4_types;

interface

uses tsxApi5;

type

  TTErfType=(NotSup,MechPart,Cage,weapon,MapMesh);

  TQuat=packed record
    X,Y,Z,W:single;
  end;

  //matrice usata in  vari modi
  PTMW4Matrix=^TMW4Matrix;
  TMW4Matrix=packed record
    case integer of
    1:(Row1 : TQuat;
       Row2 : TQuat;
       Row3 : TQuat;
       Row4 : TQuat);
    2:(M    : array[0..3,0..3] of single);
  end;

  TMW4Matrix3rw=packed record
    case integer of
    1:(Row1 : TQuat;
       Row2 : TQuat;
       Row3 : TQuat);
    2:(M    : array[0..3,0..2] of single);
  end;

//type T3Single=TD3DVector;
     PT3Single=^T3Single;
     T3Single=packed record
       X,Y,Z:single;
     end;

     PT3Byte=^T3Byte;
     T3Byte=Packed record   //describe a triangle
     p1,p2,p3:byte;
     end;

     PT3Word=^T3Word;
     T3Word=Packed record   //describe a triangle
     p1,p2,p3:Word;
     end;

     PT4Single=^T4Single;
     T4Single=packed Record
     X,Y,Z,W     :single;    //float single point 4 byte
     end;

     PT2Single=^T2Single;
     T2Single=Packed record   //float single point 4 byte
     x,y:single;
     end;

     T2Long=packed Record
     X,Y       :longword;
     end;

     PAVertex   =^TAVertex;
     TAVertex   =array of T3Single;
     PAUVVertex =^TAUVVertex;
     TAUVVertex =array of T2Single;
     PAFace     =^TAFACE;
     TAFace     =array of T3Word;
     PAPlane    =^TAplane;
     TAPlane    =array of T4single; 

function P3Single(x,y,z:single):T3single;
function P4Single(x,y,z,w:single):T4single;

function P2tostring(P:T2single):string;
function P3tostring(P:T3single):string;
function P4tostring(P:T4single):string;

//calcola l'equazione di un piano
function CalcPlaneEQ(aVertex:Tavertex;plane:T3word):T4single;
Function Normalize(v:T3Single):T3Single;
//converte i float con 8 cifre
function FloatToStr2(Value: Extended): string;

function MW4MatMult(A,B:TMW4Matrix):TMW4Matrix;
function Mw4MatIden:TMW4Matrix;
function MwMxToTsxMx(M: TMW4Matrix): CtsxTxmx3f;
function tsxMxToMwMx(M: CtsxTxmx3f): TMW4Matrix;
function tsxMxToMwMx3(M: CtsxTxmx3f): TMW4Matrix3rw;
function getRotationMx(Mx: CtsxTxmx3f): CtsxVector3f;

implementation

uses sysutils,math;

function getRotationMx(Mx: CtsxTxmx3f): CtsxVector3f;
begin
     getRotationMx.x:=radtodeg(arctan(mx.matrix[0,1]/mx.matrix[0,0]));
     getRotationMx.y:=radtodeg(arctan(mx.matrix[1,2]/mx.matrix[2,2]));
     getRotationMx.z:=radtodeg(arcsin(-mx.matrix[0,2]));
end;


function MW4MatMult(A,B:TMW4Matrix):TMW4Matrix;
var C:TMW4Matrix;
    i,j,k:integer;
begin
     for i:=0 to 3 do
        for j:=0 to 3 do
            C.M[i,j]:=0;

    for i:=0 to 3 do
        for j:=0 to 3 do
            for k:=0 to 3 do
            C.M[i,j]:=C.M[i,j]+A.M[i,k]*B.M[k,j];

    MW4MatMult:=C;
end;

function Mw4MatIden:TMW4Matrix;
var C:TMW4Matrix;
    i,j:integer;
begin
    for i:=0 to 3 do
        for j:=0 to 3 do
            if i=j then C.M[i,j]:=1
                   else C.M[i,j]:=0;
    Mw4MatIden:=C;
end;

//matrix conversion routines
function MwMxToTsxMx(M: TMW4Matrix): CtsxTxmx3f;
var i,j:integer;
    R:CtsxTxmx3f;
begin
    for i:=0 to 2
        do for j:=0 to 3
           do R.matrix[i,j]:=M.M[i,j];
    MwMxToTsxMx:=R;
end;

function tsxMxToMwMx(M: CtsxTxmx3f): TMW4Matrix;
var i,j:integer;
    R:TMW4Matrix;
begin
    for i:=0 to 2
        do for j:=0 to 3
           do R.M[i,j]:=M.matrix[i,j];
    tsxMxToMwMx:=R;
end;

function tsxMxToMwMx3(M: CtsxTxmx3f): TMW4Matrix3rw;
var
  //i,j:integer;
  R:TMW4Matrix3rw;
begin
    R.Row1.X:=M.Cols[0].vec3f.x;
    R.Row1.Y:=M.Cols[0].vec3f.y;
    R.Row1.z:=M.Cols[0].vec3f.z;
    R.Row1.w:=M.Cols[0].w;

    R.Row2.X:=M.Cols[1].vec3f.x;
    R.Row2.Y:=M.Cols[1].vec3f.y;
    R.Row2.z:=M.Cols[1].vec3f.z;
    R.Row2.w:=M.Cols[1].w;

    R.Row3.X:=M.Cols[2].vec3f.x;
    R.Row3.Y:=M.Cols[2].vec3f.y;
    R.Row3.z:=M.Cols[2].vec3f.z;
    R.Row3.w:=M.Cols[2].w;
//
//    for i:=0 to 2
//        do for j:=0 to 3
//           do R.M[i,j]:=M.matrix[i,j];
    tsxMxToMwMx3:=R;
end;
//end matrix conversion routines

function P3Single(x,y,z:single):T3single;
begin
      P3Single.x:=x;
      P3Single.y:=y;
      P3Single.z:=z;
end;

function P4Single(x,y,z,w:single):T4single;
begin
      P4Single.x:=x;
      P4Single.y:=y;
      P4Single.z:=z;
      P4Single.w:=w;
end;

function P2tostring(P:T2single):string;
begin
  P2tostring:=floattostr(P.x)+' '+floattostr(P.y);
end;

function P3tostring(P:T3single):string;
begin
  P3tostring:=floattostr(P.x)+' '+floattostr(P.y)+' '+floattostr(P.z);
end;

function P4tostring(P:T4single):string;
begin
  P4tostring:=floattostr(P.x)+' '+floattostr(P.y)+' '+floattostr(P.z)+' '+floattostr(P.w);
end;



function CalcPlaneEQ(aVertex:Tavertex;plane:T3word):T4single;
var p1,p2,p3  :T3single;  //punti del piano
    ba,bc,R   :T3single;
    N,D       :single;

begin
    {P1:=aLOD[0].meshes[m].AVertex[plane.p1];
    P2:=aLOD[0].meshes[m].AVertex[plane.p2];
    P3:=aLOD[0].meshes[m].AVertex[plane.p3];
    }
    P1:=AVertex[plane.p1];
    P2:=AVertex[plane.p2];
    P3:=AVertex[plane.p3];
    //calcolo primo vettore
    bc.x:=P1.x-P2.x;
    bc.y:=P1.y-P2.y;
    bc.z:=P1.z-P2.z;
    //calcolo secondo vettore
    ba.x:=P3.x-P2.x;
    ba.y:=P3.y-P2.y;
    ba.z:=P3.z-P2.z;
    //ricavo vettore normale r
    R.x:=(ba.y*bc.z)-(ba.z*bc.y);
    R.y:=(ba.z*bc.x)-(ba.x*bc.z);
    R.z:=(ba.x*bc.y)-(ba.y*bc.x);

    //determino la norma di r
    n:=sqrt(r.x*r.x+r.y*r.y+r.z*r.z);
    //normalizzo r
    r.x:=r.x/n;r.y:=r.y/n;r.z:=r.z/n;
    //calcolo la distanza del piano dall'origine (basta un punto qualsiasi sul piano)
    //D:=r.x*aLOD[0].meshes[m].apts[0].x+r.y*aLOD[0].meshes[m].apts[0].y+r.z*aLOD[0].meshes[m].apts[0].z;
    D:=r.x*p1.x+r.y*p1.y+r.z*p1.z;

    result.x:=r.x;
    result.y:=r.y;
    result.z:=r.z;
    result.w:=d;
end;

function FloatToStr2(Value: Extended): string;
var
  Buffer: array[0..63] of Char;
  c:char;
begin
    c:=decimalseparator;
    DecimalSeparator:='.';
    SetString(Result, Buffer, FloatToText(Buffer, Value, fvExtended,
    fffixed, 7, 6));
    DecimalSeparator:=c;
end;

Function Normalize(v:T3Single):T3Single;
var M:single;
begin
    M:=sqrt(v.x*v.x+v.y*v.y+v.z*v.z);
    result.x:=v.x/M;
    result.y:=v.y/M;
    result.z:=v.z/M;
end;
end.
