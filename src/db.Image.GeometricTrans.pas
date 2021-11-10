unit db.Image.GeometricTrans;
{
  Func: 32λλͼ���α任
  Name: dbyoung@sina.com
  Date: 2021-2-22
  Vers: Delphi 11
  Test: 4096 * 4096 * 32
  Note��Delphi �� Release ģʽ�����Ż��ģ�Debug ��û�еģ������ʱ�䣬������ X86��DEBUG ģʽ�µ���ʱ��
  Note: ���г��򣬲����� IDE �����в鿴Ч������������ IDE ִ�в鿴Ч����

  Delphi �����Ĵ���˳��
  X86: EAX, EDX, ECX
  X64: ECX, EDX, EAX

  ͨ�üĴ�����
  CPU  :
  EAX/EBX/ECX/EDX/EDI/ESI           32λ (x86)
  RAX/RBX/RCX/RDX/RDI/RSI           64λ (x64, EAX �Ĵ����� RAX �Ĵ����ĵ� 32 λ)

  SIMD�Ĵ�����
  MMX    :   MM0 --- MM7                             064λ                                         ( ��Ҫ��Ը������� )
  SSE2   :  XMM0--- XMM7                             128λ                                         ( ���� + ���� )
  SSE4   :  XMM0--- XMM7(X86)  XMM0--- XMM15(X64)    128λ                                         ( ���� + ���� )
  AVX    :  YMM0--- YMM7(X86)  YMM0--- YMM15(X64)    256λ (XMM �Ĵ����� YMM �Ĵ����ĵ� 128 λ)    ( ���� )
  AVX2   :  YMM0---YMM15                             256λ (XMM �Ĵ����� YMM �Ĵ����ĵ� 128 λ)    ( ���� + ���� )
  AVX512 :  ZMM0---ZMM31                             512λ (YMM �Ĵ����� ZMM �Ĵ����ĵ� 256 λ)    ( ���� + ���� )
}

interface

uses Winapi.Windows, System.Threading, System.Diagnostics, System.SyncObjs, System.Classes, System.Math, Vcl.Graphics, db.Image.Common;

{ ˮƽ��ת ����ģʽ����Ҫ���� IDE ִ�� }
procedure HorizMirror(bmp: TBitmap);

{ ��ֱ��ת }
procedure VertiMirror(bmp: TBitmap);

{ ת�÷�ת ����ģʽ����Ҫ���� IDE ִ�� }
procedure HAndVMirror(bmp: TBitmap);

{ ��ת }
procedure Rotate(const bmpSrc: TBitmap; var bmpDst: TBitmap; const iAngle: Integer);

implementation

uses libc, mormot.core.base;

{ ��ȡ��ı�����Ա���� }
type
  TBMPAccess         = class(TBitmap);
  TBitmapImageAccess = class(TBitmapImage);

procedure SwapDWORD(var A, B: DWORD); assembler;
asm
  MOV     EBX,   [EAX]
  XCHG    EBX,   [EDX]
  MOV     [EAX], EBX
end;

{ ˮƽ��ת ����ģʽ����Ҫ���� IDE ִ�� }
procedure HorizMirror(bmp: TBitmap);
var
  StartScanLine: Integer;
  bmpWidthBytes: Integer;
begin

  StartScanLine := Integer(bmp.ScanLine[0]);
  bmpWidthBytes := Integer(bmp.ScanLine[1]) - Integer(bmp.ScanLine[0]);

  TParallel.For(0, bmp.Height - 1,
    procedure(Y: Integer)
    var
      X: Integer;
      swapColor: DWORD;
      pColor01: PDWORD;
      pColor02: PDWORD;
    begin
      pColor01 := PDWORD(StartScanLine + Y * bmpWidthBytes);
      pColor02 := PDWORD(StartScanLine + Y * bmpWidthBytes + 4 * (bmp.Width - 1));
      for X := 0 to bmp.Width div 2 - 1 do
      begin
        swapColor := pColor02^;
        pColor02^ := pColor01^;
        pColor01^ := swapColor;
        Inc(pColor01);
        Dec(pColor02);
      end;
    end);
end;

{ ��ֱ��ת }
procedure VertiMirror(bmp: TBitmap);
var
  Y       : Integer;
  Count   : Integer;
  pColor01: Pointer;
  pColor02: Pointer;
  tmpColor: Pointer;
begin
  Count    := Integer(bmp.ScanLine[0]) - Integer(bmp.ScanLine[1]);
  tmpColor := AllocMem(Count);
  try
    for Y := 0 to bmp.Height div 2 - 1 do
    begin
      pColor01 := bmp.ScanLine[Y];
      pColor02 := bmp.ScanLine[bmp.Height - Y - 1];
      // Move(pColor01^, tmpColor^, Count);
      // Move(pColor02^, pColor01^, Count);
      // Move(tmpColor^, pColor02^, Count);
      // {$IFDEF CPUX86}
      // _memmove(tmpColor, pColor01, Count);
      // _memmove(pColor01, pColor02, Count);
      // _memmove(pColor02, tmpColor, Count);
      // {$ELSE}
      // memmove(tmpColor, pColor01, Count);
      // memmove(pColor01, pColor02, Count);
      // memmove(pColor02, tmpColor, Count);
      // {$ENDIF}
      MoveFast(pColor01^, tmpColor^, Count);
      MoveFast(pColor02^, pColor01^, Count);
      MoveFast(tmpColor^, pColor02^, Count);
    end;
  finally
    FreeMem(tmpColor);
  end;
end;

{ ת�÷�ת ����ģʽ����Ҫ���� IDE ִ�� }
procedure HAndVMirror(bmp: TBitmap);
begin
  HorizMirror(bmp);
  VertiMirror(bmp);
end;

{
  �����ͼƬ�������(x,y)����һ�������(rx0,ry0)��ʱ����תRotaryAngle�ǶȺ���µ�������Ϊ(x', y')���й�ʽ��
  x'= (x - rx0)*cos(RotaryAngle) + (y - ry0)*sin(RotaryAngle) + rx0 ;
  y'=-(x - rx0)*sin(RotaryAngle) + (y - ry0)*cos(RotaryAngle) + ry0 ;

  ��ô�������µ��������Դ�����Ĺ�ʽΪ��
  x=(x'- rx0)*cos(RotaryAngle) - (y'- ry0)*sin(RotaryAngle) + rx0 ;
  y=(x'- rx0)*sin(RotaryAngle) + (y'- ry0)*cos(RotaryAngle) + ry0 ;
}

{ ��׼��ת���� }
procedure Optimize01(bmpSrc, bmpDst: TBitmap; const RotaryAngle: double; const CenterX, CenterY, MoveX, MoveY: Integer);
var
  X, Y      : Integer;
  SrcX, SrcY: Integer;
begin
  for Y := 0 to bmpDst.Height - 1 do
  begin
    for X := 0 to bmpDst.Width - 1 do
    begin
      SrcX                       := Round((X - CenterX - MoveX) * Cos(RotaryAngle) - (Y - CenterY - MoveY) * Sin(RotaryAngle) + CenterX);
      SrcY                       := Round((X - CenterX - MoveX) * Sin(RotaryAngle) + (Y - CenterY - MoveY) * Cos(RotaryAngle) + CenterY);
      bmpDst.Canvas.Pixels[X, Y] := bmpSrc.Canvas.Pixels[SrcX, SrcY];
    end;
  end;
end;

{ �Ż� Pixels }
procedure Optimize02(bmpSrc, bmpDst: TBitmap; const RotaryAngle: double; const CenterX, CenterY, MoveX, MoveY: Integer);
var
  X, Y      : Integer;
  SrcX, SrcY: Integer;
  srcBits   : PRGBQuadArray;
  dstBits   : PRGBQuadArray;
  dstWidth  : Integer;
  dstHeight : Integer;
  srcWidth  : Integer;
  srcHeight : Integer;
begin
  srcBits := TBitmapImageAccess(TBMPAccess(bmpSrc).FImage).FDIB.dsBm.bmBits;
  dstBits := TBitmapImageAccess(TBMPAccess(bmpDst).FImage).FDIB.dsBm.bmBits;

  dstWidth  := bmpDst.Width;
  dstHeight := bmpDst.Height;
  srcWidth  := bmpSrc.Width;
  srcHeight := bmpSrc.Height;

  for Y := 0 to dstHeight - 1 do
  begin
    for X := 0 to dstWidth - 1 do
    begin
      SrcX := Round((X - CenterX - MoveX) * Cos(RotaryAngle) - (Y - CenterY - MoveY) * Sin(RotaryAngle) + CenterX);
      SrcY := Round((X - CenterX - MoveX) * Sin(RotaryAngle) + (Y - CenterY - MoveY) * Cos(RotaryAngle) + CenterY);
      if (DWORD(SrcY) < DWORD(srcHeight)) and (DWORD(SrcX) < DWORD(srcWidth)) then
      begin
        dstBits[Y * dstWidth + X] := srcBits[SrcY * srcWidth + SrcX];
      end;
    end;
  end;
end;

{ �Ż�ѭ�� }
procedure Optimize03(bmpSrc, bmpDst: TBitmap; const RotaryAngle: double; const CenterX, CenterY, MoveX, MoveY: Integer);
var
  X, Y      : Integer;
  SrcX, SrcY: Integer;
  srcBits   : PRGBQuadArray;
  dstBits   : PRGBQuadArray;
  cxc, cxs  : Single;
  cyc, cys  : Single;
  rac, ras  : Single;
  dstWidth  : Integer;
  dstHeight : Integer;
  srcWidth  : Integer;
  srcHeight : Integer;
  krx, kry  : Single;
begin
  srcBits := TBitmapImageAccess(TBMPAccess(bmpSrc).FImage).FDIB.dsBm.bmBits;
  dstBits := TBitmapImageAccess(TBMPAccess(bmpDst).FImage).FDIB.dsBm.bmBits;

  dstWidth  := bmpDst.Width;
  dstHeight := bmpDst.Height;
  srcWidth  := bmpSrc.Width;
  srcHeight := bmpSrc.Height;

  rac := Cos(RotaryAngle);
  ras := Sin(RotaryAngle);
  cxc := (CenterX + MoveX) * rac;
  cxs := (CenterX + MoveX) * ras;
  cys := (CenterY + MoveY) * ras;
  cyc := (CenterY + MoveY) * rac;

  for Y := 0 to dstHeight - 1 do
  begin
    krx   := cxc - cys - CenterX + Y * ras;
    kry   := cxs + cyc - CenterY - Y * rac;
    for X := 0 to dstWidth - 1 do
    begin
      SrcX := Round(X * rac - krx);
      SrcY := Round(X * ras - kry);
      if (DWORD(SrcY) < DWORD(srcHeight)) and (DWORD(SrcX) < DWORD(srcWidth)) then
      begin
        dstBits[Y * dstWidth + X] := srcBits[SrcY * srcWidth + SrcX];
      end;
    end;
  end;
end;

{ �Ż���������Ϊ�������� }
procedure Optimize04(bmpSrc, bmpDst: TBitmap; const RotaryAngle: double; const CenterX, CenterY, MoveX, MoveY: Integer);
var
  X, Y      : Integer;
  SrcX, SrcY: Integer;
  srcBits   : PRGBQuadArray;
  dstBits   : PRGBQuadArray;
  cxc, cxs  : Integer;
  cyc, cys  : Integer;
  rac, ras  : Integer;
  kcx, kcy  : Integer;
  dstWidth  : Integer;
  dstHeight : Integer;
  srcWidth  : Integer;
  srcHeight : Integer;
  krx, kry  : Integer;
begin
  srcBits := TBitmapImageAccess(TBMPAccess(bmpSrc).FImage).FDIB.dsBm.bmBits;
  dstBits := TBitmapImageAccess(TBMPAccess(bmpDst).FImage).FDIB.dsBm.bmBits;

  dstWidth  := bmpDst.Width;
  dstHeight := bmpDst.Height;
  srcWidth  := bmpSrc.Width;
  srcHeight := bmpSrc.Height;

  rac := Trunc(Cos(RotaryAngle) * (1 shl 16));
  ras := Trunc(Sin(RotaryAngle) * (1 shl 16));
  cxc := (CenterX + MoveX) * rac;
  cxs := (CenterX + MoveX) * ras;
  cys := (CenterY + MoveY) * ras;
  cyc := (CenterY + MoveY) * rac;
  kcx := cxc - cys - CenterX * (1 shl 16);
  kcy := cxs + cyc - CenterY * (1 shl 16);

  for Y := 0 to dstHeight - 1 do
  begin
    krx   := kcx + Y * ras;
    kry   := kcy - Y * rac;
    for X := 0 to dstWidth - 1 do
    begin
      SrcX := SmallInt((X * rac - krx) shr 16);
      SrcY := SmallInt((X * ras - kry) shr 16);
      if (DWORD(SrcY) < DWORD(srcHeight)) and (DWORD(SrcX) < DWORD(srcWidth)) then
      begin
        dstBits[Y * dstWidth + X] := srcBits[SrcY * srcWidth + SrcX];
      end;
    end;
  end;
end;

{ �����Ż� }
procedure Optimize05(bmpSrc, bmpDst: TBitmap; const RotaryAngle: double; const CenterX, CenterY, MoveX, MoveY: Integer);
var
  srcBits  : PRGBQuadArray;
  dstBits  : PRGBQuadArray;
  cxc, cxs : Integer;
  cyc, cys : Integer;
  rac, ras : Integer;
  kcx, kcy : Integer;
  dstWidth : Integer;
  dstHeight: Integer;
  srcWidth : Integer;
  srcHeight: Integer;
begin
  srcBits := TBitmapImageAccess(TBMPAccess(bmpSrc).FImage).FDIB.dsBm.bmBits;
  dstBits := TBitmapImageAccess(TBMPAccess(bmpDst).FImage).FDIB.dsBm.bmBits;

  dstWidth  := bmpDst.Width;
  dstHeight := bmpDst.Height;
  srcWidth  := bmpSrc.Width;
  srcHeight := bmpSrc.Height;

  rac := Trunc(Cos(RotaryAngle) * (1 shl 16));
  ras := Trunc(Sin(RotaryAngle) * (1 shl 16));
  cxc := (CenterX + MoveX) * rac;
  cxs := (CenterX + MoveX) * ras;
  cys := (CenterY + MoveY) * ras;
  cyc := (CenterY + MoveY) * rac;
  kcx := cxc - cys - CenterX * (1 shl 16);
  kcy := cxs + cyc - CenterY * (1 shl 16);

  TParallel.For(0, dstHeight - 1,
    procedure(Y: Integer)
    var
      X: Integer;
      krx, kry: Integer;
      SrcX, SrcY: Integer;
    begin
      krx := kcx + Y * ras;
      kry := kcy - Y * rac;
      for X := 0 to dstWidth - 1 do
      begin
        SrcX := SmallInt((X * rac - krx) shr 16);
        SrcY := SmallInt((X * ras - kry) shr 16);
        if (DWORD(SrcY) < DWORD(srcHeight)) and (DWORD(SrcX) < DWORD(srcWidth)) then
        begin
          dstBits[Y * dstWidth + X] := srcBits[SrcY * srcWidth + SrcX];
        end;
      end;
    end);
end;

procedure Rotate_Proc01(const krx, kry, IndexRow: Integer; const srcBits: PRGBQuadArray; dstBits: PRGBQuadArray; const rac, ras: Integer; const dstWidth, srcWidth, srcHeight: DWORD); assembler; inline;
var
  X         : Integer;
  SrcX, SrcY: DWORD;
begin
  for X := dstWidth - 1 downto 0 do
  begin
    SrcX := (X * rac - krx) shr 16;
    SrcY := (X * ras - kry) shr 16;
    if (SrcY < srcHeight) and (SrcX < srcWidth) then
    begin
      dstBits[IndexRow * Integer(dstWidth) + X] := srcBits[SrcY * srcWidth + SrcX];
    end;
  end;
end;

procedure Rotate_Proc02(const krx, kry, IndexRow: Integer; const srcBits: PRGBQuadArray; dstBits: PRGBQuadArray; const rac, ras: Integer; const dstWidth, srcWidth, srcHeight: DWORD); assembler;
asm
  MOV  [EBP-$04], EAX          // [EBP-$04] = krx
  MOV  [EBP-$08], EDX          // [EBP-$08] = kry
  MOV  EBX, ECX                // EBX = IndexRow
  MOV  ECX, dstWidth           // ECX = dstWidth ѭ������

@LOOP:
  MOV   EAX,  ECX               // EAX = X
  IMUL  EAX,  rac               // EAX = X * rac
  SUB   EAX,  [EBP-$04]         // EAX = X * rac - krx
  SHR   EAX,  16                // EAX = (X * rac - krx) shr 16  = SrcX

  MOV   EDX,  ECX               // EDX = X
  IMUL  EDX,  ras               // EDX = X * ras
  SUB   EDX,  [EBP-$08]         // EDX = X * ras - kry
  SHR   EDX,  16                // EDX = (X * ras - kry) shr 16  = SrcY

  CMP   EAX,  srcWidth          // IF SrcX < srcWidth
  JNB   @NEXT                   //
  CMP   EDX,  srcHeight         // IF SrcY < srcHeight
  JNB   @NEXT                   //

  MOV  EDI,  EDX                // EDI = (X * ras - kry) shr 16  = SrcY
  IMUL EDI,  srcWidth           // EDI = SrcY * srcWidth
  ADD  EDI,  EAX                // EDI = SrcY * srcWidth + SrcX
  MOV  EDX,  [srcBits]          // EDI = [srcBits]
  MOV  EDI,  [EDX + EDI * 4]    // EDI = srcBits[SrcY * srcWidth + SrcX]

  MOV  EDX,  EBX                // EDX = IndexRow
  IMUL EDX,  dstWidth           // EDX = IndexRow * dstWidth
  ADD  EDX,  ECX                // EDX = IndexRow * dstWidth + X
  MOV  ESI,  [dstBits]          // ESI = [dstBits]
  MOV  [ESI + EDX * 4], EDI     // dstBits[IndexRow * Integer(dstWidth) + X] = EDI

@NEXT:
  DEC  ECX
  JNZ  @LOOP
  MOV  ESP,  EBP
END;

procedure Rotate_Proc03(const krx, kry, IndexRow: Integer; const srcBits: PRGBQuadArray; dstBits: PRGBQuadArray; const rac, ras: Integer; const dstWidth, srcWidth, srcHeight: DWORD); assembler;
asm
  MOV  EBX, ECX           // EBX = IndexRow
  MOV  ECX, dstWidth      // ECX = dstWidth ѭ������

@LOOP:


@NEXT:
  DEC ECX
  JNZ @LOOP
  MOV ESP,EBP
end;

{ ���� + SIMD �Ż� }
procedure Optimize06(bmpSrc, bmpDst: TBitmap; const RotaryAngle: double; const CenterX, CenterY, MoveX, MoveY: Integer);
var
  srcBits  : PRGBQuadArray;
  dstBits  : PRGBQuadArray;
  cxc, cxs : Integer;
  cyc, cys : Integer;
  rac, ras : Integer;
  kcx, kcy : Integer;
  dstWidth : Integer;
  dstHeight: Integer;
  srcWidth : Integer;
  srcHeight: Integer;
begin
  srcBits := TBitmapImageAccess(TBMPAccess(bmpSrc).FImage).FDIB.dsBm.bmBits;
  dstBits := TBitmapImageAccess(TBMPAccess(bmpDst).FImage).FDIB.dsBm.bmBits;

  dstWidth  := bmpDst.Width;
  dstHeight := bmpDst.Height;
  srcWidth  := bmpSrc.Width;
  srcHeight := bmpSrc.Height;

  rac := Trunc(Cos(RotaryAngle) * (1 shl 16));
  ras := Trunc(Sin(RotaryAngle) * (1 shl 16));
  cxc := (CenterX + MoveX) * rac;
  cxs := (CenterX + MoveX) * ras;
  cys := (CenterY + MoveY) * ras;
  cyc := (CenterY + MoveY) * rac;
  kcx := cxc - cys - CenterX * (1 shl 16);
  kcy := cxs + cyc - CenterY * (1 shl 16);

  TParallel.For(0, dstHeight - 1,
    procedure(IndexRow: Integer)
    var
      krx, kry: Integer;
    begin
      krx := kcx + IndexRow * ras;
      kry := kcy - IndexRow * rac;
      Rotate_Proc02(krx, kry, IndexRow, srcBits, dstBits, rac, ras, dstWidth, srcWidth, srcHeight);
    end);
end;

procedure Rotate(const bmpSrc: TBitmap; var bmpDst: TBitmap; const iAngle: Integer);
var
  RotaryAngle     : double;
  CenterX, CenterY: Integer;
  MoveX, MoveY    : Integer;
begin
  RotaryAngle               := (iAngle mod 360) * PI / 180;
  bmpDst.PixelFormat        := pf32bit;
  bmpDst.Width              := Round(ABS(bmpSrc.Width * Cos(RotaryAngle)) + ABS(bmpSrc.Height * Sin(RotaryAngle)));
  bmpDst.Height             := Round(ABS(bmpSrc.Width * Sin(RotaryAngle)) + ABS(bmpSrc.Height * Cos(RotaryAngle)));
  bmpDst.Canvas.Brush.Color := clBlack;
  bmpDst.Canvas.FillRect(bmpDst.Canvas.ClipRect);

  MoveX   := (bmpDst.Width - bmpSrc.Width) div 2;
  MoveY   := (bmpDst.Height - bmpSrc.Height) div 2;
  CenterX := bmpSrc.Width div 2;
  CenterY := bmpSrc.Height div 2;

  Optimize06(bmpSrc, bmpDst, RotaryAngle, CenterX, CenterY, MoveX, MoveY);
end;

end.
