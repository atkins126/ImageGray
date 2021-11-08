unit db.Image.Effect;
{
  Func: 32λλͼЧ��ͼ
  Name: dbyoung@sina.com
  Date: 2021-2-25
  Vers: Delphi 11
  Test: 4096 * 4096 * 32
  Note��Delphi �� Release ģʽ�����Ż��ģ�Debug ��û�еģ������ʱ�䣬������ DEBUG ģʽ�µ���ʱ��
  Note: ���г��򣬲����� IDE �����в鿴Ч������������ IDE ִ�в鿴Ч����

  Delphi �����Ĵ���˳��
  X86: EAX, EDX, ECX
  X64: ECX, EDX, EAX

  ͨ�üĴ�����
  CPU  :
  EAX/EBX/ECX/EDX/EDI/ESI           32λ (x86)
  RAX/RBX/RCX/RDX/RDI/RSI           64λ (x64, EAX �Ĵ����� RAX �Ĵ����ĵ� 32 λ)

  SIMD�Ĵ�����
  MMX    :   MM0 --- MM7    064λ                                         ( ��Ҫ��Ը������� )
  SSE2   :  XMM0--- XMM7    128λ                                         ( ���� + ���� )
  SSE4   :  XMM0---XMM15    128λ                                         ( ���� + ���� )
  AVX    :  YMM0---YMM15    256λ (XMM �Ĵ����� YMM �Ĵ����ĵ� 128 λ)    ( ���� )
  AVX2   :  YMM0---YMM15    256λ (XMM �Ĵ����� YMM �Ĵ����ĵ� 128 λ)    ( ���� + ���� )
  AVX512 :  ZMM0---ZMM31    512λ (YMM �Ĵ����� ZMM �Ĵ����ĵ� 256 λ)    ( ���� + ���� )
}

interface

uses Winapi.Windows, System.Threading, System.Math, Vcl.Graphics, db.Image.Common;

{ �ع� }
procedure Exposure(bmp: TBitmap);

{ ���� }
procedure Emboss(bmp: TBitmap);

{ ��� }
procedure Engrave(bmp: TBitmap);

{ ģ�� }
procedure Blur(bmp: TBitmap);

{ �� }
procedure Sharpen(bmp: TBitmap);

{ �ͻ� }
procedure Sponge(ABmp: TBitmap);

implementation

uses Forms;

{ �ع� }
procedure Exposure(bmp: TBitmap);
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
      pColor: PRGBQuad;
    begin
      pColor := PRGBQuad(StartScanLine + Y * bmpWidthBytes);
      for X := 0 to bmp.Width - 1 do
      begin
        pColor^.rgbBlue := Ifthen(pColor^.rgbBlue < 128, not pColor^.rgbBlue, pColor^.rgbBlue);
        pColor^.rgbGreen := Ifthen(pColor^.rgbGreen < 128, not pColor^.rgbGreen, pColor^.rgbGreen);
        pColor^.rgbRed := Ifthen(pColor^.rgbRed < 128, not pColor^.rgbRed, pColor^.rgbRed);
        Inc(pColor);
      end;
    end);
end;

{ ���� }
procedure Emboss(bmp: TBitmap);
// var
// X, Y    : Integer;
// pColor01: PRGBQuad;
// pColor02: PRGBQuad;
// begin
// for Y := 0 to bmp.Height - 2 do
// begin
// pColor01 := bmp.ScanLine[Y + 0];
// pColor02 := bmp.ScanLine[Y + 1];
// for X    := 0 to bmp.Width - 1 do
// begin
// Inc(pColor02);
// pColor01^.rgbRed   := EnsureRange(pColor01^.rgbRed - pColor02^.rgbRed + 128, 0, 255);
// pColor01^.rgbGreen := EnsureRange(pColor01^.rgbGreen - pColor02^.rgbGreen + 128, 0, 255);
// pColor01^.rgbBlue  := EnsureRange(pColor01^.rgbBlue - pColor02^.rgbBlue + 128, 0, 255);
// Inc(pColor01);
// end;
// end;
// end;
var
  StartScanLine: Integer;
  bmpWidthBytes: Integer;
begin
  StartScanLine := Integer(bmp.ScanLine[0]);
  bmpWidthBytes := Integer(bmp.ScanLine[1]) - Integer(bmp.ScanLine[0]);

  TParallel.For(0, bmp.Height - 2,
    procedure(Y: Integer)
    var
      X: Integer;
      pColor01: PRGBQuad;
      pColor02: PRGBQuad;
    begin
      pColor01 := PRGBQuad(StartScanLine + (Y + 0) * bmpWidthBytes);
      pColor02 := PRGBQuad(StartScanLine + (Y + 1) * bmpWidthBytes);
      for X := 0 to bmp.Width - 1 do
      begin
        Inc(pColor02);
        pColor01^.rgbRed := EnsureRange(pColor01^.rgbRed - pColor02^.rgbRed + 128, 0, 255);
        pColor01^.rgbGreen := EnsureRange(pColor01^.rgbGreen - pColor02^.rgbGreen + 128, 0, 255);
        pColor01^.rgbBlue := EnsureRange(pColor01^.rgbBlue - pColor02^.rgbBlue + 128, 0, 255);
        Inc(pColor01);
      end;
    end);
end;

{ ��� }
procedure Engrave(bmp: TBitmap);
var
  X, Y      : Integer;
  pColor01  : PRGBQuad;
  SrcNextRow: PRGBQuad;
begin
  for Y := 0 to bmp.Height - 2 do
  begin
    pColor01   := bmp.ScanLine[Y + 0];
    SrcNextRow := bmp.ScanLine[Y + 1];
    for X      := 0 to bmp.Width - 1 do
    begin
      Inc(SrcNextRow);
      pColor01^.rgbRed   := EnsureRange(SrcNextRow^.rgbRed - pColor01^.rgbRed + 128, 0, 255);
      pColor01^.rgbGreen := EnsureRange(SrcNextRow^.rgbGreen - pColor01^.rgbGreen + 128, 0, 255);
      pColor01^.rgbBlue  := EnsureRange(SrcNextRow^.rgbBlue - pColor01^.rgbBlue + 128, 0, 255);
      Inc(pColor01);
    end;
  end;
end;

{ ģ�� }
procedure Blur(bmp: TBitmap);
var
  X, Y                  : Integer;
  pColorPre             : PRGBQuad;
  pColorOne             : PRGBQuad;
  pColorTwo             : PRGBQuad;
  ValueR, ValueG, ValueB: Integer;
begin
  for Y := 1 to bmp.Height - 2 do
  begin
    pColorOne := bmp.ScanLine[Y + 0];
    pColorTwo := bmp.ScanLine[Y + 1];
    pColorPre := bmp.ScanLine[Y - 1];
    for X     := 1 to bmp.Width - 2 do
    begin
      ValueR := pColorPre^.rgbRed + pColorOne^.rgbRed + pColorTwo^.rgbRed;
      ValueG := pColorPre^.rgbGreen + pColorOne^.rgbGreen + pColorTwo^.rgbGreen;
      ValueB := pColorPre^.rgbBlue + pColorOne^.rgbBlue + pColorTwo^.rgbBlue;

      Inc(pColorPre);
      Inc(pColorOne);
      Inc(pColorTwo);
      ValueR := ValueR + pColorPre^.rgbRed + pColorOne^.rgbRed + pColorTwo^.rgbRed;
      ValueG := ValueG + pColorPre^.rgbGreen + pColorOne^.rgbGreen + pColorTwo^.rgbGreen;
      ValueB := ValueB + pColorPre^.rgbBlue + pColorOne^.rgbBlue + pColorTwo^.rgbBlue;

      Inc(pColorPre);
      Inc(pColorOne);
      Inc(pColorTwo);
      ValueR := ValueR + pColorPre^.rgbRed + pColorOne^.rgbRed + pColorTwo^.rgbRed;
      ValueG := ValueG + pColorPre^.rgbGreen + pColorOne^.rgbGreen + pColorTwo^.rgbGreen;
      ValueB := ValueB + pColorPre^.rgbBlue + pColorOne^.rgbBlue + pColorTwo^.rgbBlue;

      pColorOne^.rgbRed   := ValueR div 9;
      pColorOne^.rgbGreen := ValueG div 9;
      pColorOne^.rgbBlue  := ValueB div 9;

      Dec(pColorPre);
      Dec(pColorOne);
      Dec(pColorTwo);
    end;
  end;
end;

{ �� }
procedure Sharpen(bmp: TBitmap);
var
  StartScanLine: Integer;
  bmpWidthBytes: Integer;
begin
  StartScanLine := Integer(bmp.ScanLine[0]);
  bmpWidthBytes := Integer(bmp.ScanLine[1]) - Integer(bmp.ScanLine[0]);

  TParallel.For(1, bmp.Height - 2,
    procedure(Y: Integer)
    var
      X: Integer;
      pColor01: PRGBQuad;
      pColor02: PRGBQuad;
    begin
      pColor01 := PRGBQuad(StartScanLine + (Y - 0) * bmpWidthBytes);
      pColor02 := PRGBQuad(StartScanLine + (Y - 1) * bmpWidthBytes);
      for X := 0 to bmp.Width - 1 do
      begin
        Dec(pColor02);
        pColor01^.rgbRed := EnsureRange(pColor01^.rgbRed + (pColor01^.rgbRed - pColor02^.rgbRed) div 2, 0, 255);
        pColor01^.rgbGreen := EnsureRange(pColor01^.rgbGreen + (pColor01^.rgbGreen - pColor02^.rgbGreen) div 2, 0, 255);
        pColor01^.rgbBlue := EnsureRange(pColor01^.rgbBlue + (pColor01^.rgbBlue - pColor02^.rgbBlue) div 2, 0, 255);
        Inc(pColor01);
        Inc(pColor02, 2);
      end;
    end);
end;

type
  pRGBArray  = ^TRGBArray;
  PbyteArray = ^TByteArray;
  TRGBArray  = array [0 .. 32768 - 1] of TRGBQuad;
  TByteArray = array [0 .. 16777215] of Byte;

  { �ͻ� }
procedure Sponge(ABmp: TBitmap);
var
  I, J, X, Y, R: Integer;
begin
  for I   := 0 to ABmp.Height - 1 do
    for J := 0 to ABmp.Width - 1 do
    begin
      Application.ProcessMessages;
      Randomize;
      R                                       := Random(128);
      X                                       := EnsureRange(J + (R - Random(R * 2)), 0, ABmp.Width - 1);
      Y                                       := EnsureRange(I + (R - Random(R * 2)), 0, ABmp.Height - 1);
      PbyteArray(ABmp.ScanLine[I])[J * 4 + 0] := PbyteArray(ABmp.ScanLine[Y])[X * 4 + 0];
      PbyteArray(ABmp.ScanLine[I])[J * 4 + 1] := PbyteArray(ABmp.ScanLine[Y])[X * 4 + 1];
      PbyteArray(ABmp.ScanLine[I])[J * 4 + 2] := PbyteArray(ABmp.ScanLine[Y])[X * 4 + 2];
    end;
end;

end.
