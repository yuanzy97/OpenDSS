unit DYMatrix;

interface

Uses Arraydef, UComplex, Solution;

Function  InitAndGetYparams(var hY, nBus, nNZ:LongWord): Longword; StdCall;
Procedure GetCompressedYMatrix(hY, nBus, nNz:Longword; Var ColPtr, RowIdx:pIntegerArray; Var cVals:pComplexArray); StdCall;
//01202016
procedure ZeroInjCurr; Stdcall;
procedure GetSourceInjCurrents; Stdcall;
procedure GetPCInjCurr; Stdcall;
function SystemYChanged(mode, arg: longint): longint; Stdcall;
procedure BuildYMatrixD(BuildOps, AllocateVI: longint); Stdcall;
function UseAuxCurrents(mode, arg: longint): longint; Stdcall;
procedure AddInAuxCurrents(SType: integer); Stdcall;
procedure getIpointer(var IvectorPtr: pComplexArray);Stdcall;
procedure getVpointer(var VvectorPtr: pComplexArray);Stdcall;
function SolveSystem(var NodeV:pNodeVarray): integer; stdcall;


implementation

Uses DSSGlobals, Ymatrix;

Var {Global variables in this Module}
   Yhandle, NumNZ, NumBuses : LongWord;
   YColumns,
   YRows   : pIntegerArray;
   YValues, IVector, VVector : pComplexArray;


Function InitAndGetYparams(var hY, nBus, nNZ:LongWord): Longword; StdCall;

// Call this first

// Save a copy of these in permanent heap memory here before returning

Begin
  Result := 0;    // indicates error
  If ActiveCircuit=Nil then Exit;
  Yhandle := ActiveCircuit.Solution.hY;
  If Yhandle <= 0 Then Begin
     DoSimpleMsg('Y Matrix not Built.', 222);
     Exit;
  End;

  hY := Yhandle;

  FactorSparseMatrix (hY);
  GetNNZ  (hY, @NumNz);
  GetSize (hY, @NumBuses);

  nBus := NumBuses;
  nNZ  := NumNZ;

  Result := 1;
End;


Procedure GetCompressedYMatrix(hY, nBus, nNz:Longword; Var ColPtr, RowIdx:pIntegerArray; Var cVals:pComplexArray); StdCall;

{Returns Pointers to column and row and matrix values}

{Call InitAndGetYparams first to factor the sparse matrix ...}

Begin

 // Allocate space on the heap and put the values there
     ReAllocmem(YColumns, sizeof(YColumns^[1])*(nBus+1));
     ReAllocmem(YRows,    sizeof(YRows^[1])   *nNZ);
     ReAllocmem(YValues,  sizeof(YValues^[1]) *nNZ);
     // Fill in the memory
     GetCompressedMatrix (hY, nBus + 1, nNZ, @YColumns^[1], @YRows^[1], @YValues^[1]);

     // Set the pointers in the calling program to the heap variables
     ColPtr := YColumns;
     RowIdx := YRows;
     cVals  := YValues;
End;

procedure ZeroInjCurr; Stdcall;
Begin
     IF ActiveCircuit <> Nil THEN ActiveCircuit.Solution.ZeroInjCurr;
end;

procedure GetSourceInjCurrents; Stdcall;
Begin
     IF ActiveCircuit <> Nil THEN ActiveCircuit.Solution.GetSourceInjCurrents;
end;

procedure GetPCInjCurr; Stdcall;
Begin
     IF ActiveCircuit <> Nil THEN ActiveCircuit.Solution.GetPCInjCurr;
end;

function SystemYChanged(mode, arg: longint): longint; Stdcall;
begin
    Result:=0;
    case mode of
        0: if ActiveCircuit.Solution.SystemYChanged then  Result:=1;  // Read
        1: begin                                                      // Write
           if arg=1 then ActiveCircuit.Solution.SystemYChanged:= TRUE
           else ActiveCircuit.Solution.SystemYChanged:= FALSE;
        end;
    end;
end;

procedure BuildYMatrixD(BuildOps, AllocateVI: longint); Stdcall;
var
  AllocateV: boolean;
begin
   AllocateV:=FALSE;
   if AllocateVI=1 then AllocateV:=TRUE;
   BuildYMatrix(BuildOps,AllocateV);
end;

function UseAuxCurrents(mode, arg: longint): longint; Stdcall;
begin
    Result:=0;
    case mode of
        0: if ActiveCircuit.Solution.UseAuxCurrents then  Result:=1;  // Read
        1: begin                                                      // Write
           if arg=1 then ActiveCircuit.Solution.UseAuxCurrents:= TRUE
           else ActiveCircuit.Solution.UseAuxCurrents:= FALSE;
        end;
    end;
end;

procedure AddInAuxCurrents(SType: integer); Stdcall;
begin
    ActiveCircuit.Solution.AddInAuxCurrents(SType);
end;

procedure getIpointer(var IvectorPtr: pComplexArray);Stdcall;
begin
     ReAllocmem(IVector,sizeof(IVector^[1])*NumNZ);
     IVectorPtr:=IVector;
end;

procedure getVpointer(var VvectorPtr: pComplexArray);Stdcall;
begin
     ReAllocmem(VVector,sizeof(VVector^[1])*NumNZ);
     VVectorPtr:=VVector;
end;

function SolveSystem(var NodeV:pNodeVarray): integer; stdcall;
begin
  Result:=ActiveCircuit.Solution.SolveSystem(NodeV);
end;

//---------------------------------------------------------------------------------

initialization

// Initialize so Reallocmem will work reliably
   Ycolumns := Nil;
   YRows    := Nil;
   YValues  := Nil;

finalization

// Be a good citizen and clean up
     ReAllocmem(YColumns, 0);
     ReAllocmem(YRows,    0);
     ReAllocmem(YValues,  0);

end.
