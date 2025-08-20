unit tsxApi5;
    interface
    type
      tsxGNode = Pointer;
      CtsxVector3f = record x, y, z: Single; end;
      CtsxTxmx3f = record matrix: array[0..2, 0..3] of Single; end;
      CtsxSobjType = (e_tsxFALSE, e_tsxGROUP);
    procedure tsxGNodeSetName(Node: tsxGNode; Name: PChar);
    procedure tsxGNodeGetName(Node: tsxGNode; var Name: array of Char; Len: Integer);
    procedure tsxGNodeGetAxesPosition(Node: tsxGNode; var Pos: CtsxVector3f);
    function tsxSobjGetType(Node: tsxGNode): CtsxSobjType;
    function tsxGNodeGetFirstChild(Node: tsxGNode): tsxGNode;
    function tsxSobjGetNext(Node: tsxGNode): tsxGNode;
    procedure tsxPolyhInvertFaceNormals(Node: tsxGNode);
    procedure tsxSceneAddObject(Node: tsxGNode; Flag: CtsxSobjType);
    function tsxGroupAtCurrobj(Node: tsxGNode): tsxGNode;
    implementation
    procedure tsxGNodeSetName(Node: tsxGNode; Name: PChar); begin end;
    procedure tsxGNodeGetName(Node: tsxGNode; var Name: array of Char; Len: Integer); begin end;
    procedure tsxGNodeGetAxesPosition(Node: tsxGNode; var Pos: CtsxVector3f); begin end;
    function tsxSobjGetType(Node: tsxGNode): CtsxSobjType; begin Result := e_tsxFALSE; end;
    function tsxGNodeGetFirstChild(Node: tsxGNode): tsxGNode; begin Result := nil; end;
    function tsxSobjGetNext(Node: tsxGNode): tsxGNode; begin Result := nil; end;
    procedure tsxPolyhInvertFaceNormals(Node: tsxGNode); begin end;
    procedure tsxSceneAddObject(Node: tsxGNode; Flag: CtsxSobjType); begin end;
    function tsxGroupAtCurrobj(Node: tsxGNode): tsxGNode; begin Result := nil; end;
    end.