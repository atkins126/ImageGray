unit db.Image.ColorMap;
{
  Func: 32λλͼͼ��ɫ��
  Name: dbyoung@sina.com
  Date: 2021-2-24
  Vers: Delphi 10.3.2
  Test: 4096 * 4096 * 32
  Note��Delphi �� Release ģʽ�����Ż��ģ�Debug ��û�еģ������ʱ�䣬������ DEBUG ģʽ�µ���ʱ��
}

interface

uses Winapi.Windows, System.Threading, System.Math, Vcl.Graphics, db.Image.Common;

type
  TColorMapType = (cmtScanline, cmtParallel, cmtSSEParallel, cmtSSE2, cmtSSE4, cmtAVX1, cmtAVX2, cmtAVX512knl, cmtAVX512skx);

procedure ColorMap(bmp: TBitmap; const intColorMapValue: Integer; const cmt: TColorMapType = cmtSSEParallel);

implementation

procedure RGBToHSV(const R, G, B: Single; var H, S, V: Single);
var
  cDelta    : Single;
  kDelta    : Single;
  iMax, iMin: Single;
begin
  iMax   := MaxValue([R, G, B]);
  iMin   := MinValue([R, G, B]);
  cDelta := iMax - iMin;
  V      := iMax;

  if cDelta = 0.0 then
  begin
    H := 0;
    S := 0;
    Exit;
  end;

  if V = 0.0 then
    S := 0
  else
    S := cDelta / iMax;

  if S = 0.0 then
  begin
    H := NaN;
    Exit;
  end;

  kDelta := 1 / cDelta;
  if R = V then
    H := 60.0 * (G - B) * kDelta
  else if G = V then
    H := 120.0 + 60.0 * (B - R) * kDelta
  else if B = V then
    H := 240.0 + 60.0 * (R - G) * kDelta;

  if H < 0.0 then
    H := H + 360.0
end;

procedure RGBToHSV_Opt(R, G, B: Single; var H, S, V: Single);
var
  K  : Single;
  tmp: Single;
  sst: Single;
begin
  K   := 0.0;
  sst := 0.00000000000000000001;

  if G < B then
  begin
    tmp := G;
    G   := B;
    B   := tmp;
    K   := -1.0;
  end;

  if R < G then
  begin
    tmp := R;
    R   := G;
    G   := tmp;
    K   := -2 / (6 - K);
  end;

  tmp := R - Min(G, B);
  H   := abs(K + (G - B) / (6.0 * tmp + sst));
  S   := tmp / (R + sst);
  V   := R;
end;

procedure HSVtoRGB(const H, S, V: Single; var R, G, B: Single);
var
  f      : Single;
  I      : Integer;
  hTemp  : Single;
  p, q, t: Single;
begin
  if S = 0.0 then
  begin
    if H = 0 then
    begin
      R := V;
      G := V;
      B := V
    end;
  end
  else
  begin
    if H = 360.0 then
      hTemp := 0.0
    else
      hTemp := H;

    hTemp := hTemp / 60;
    I     := TRUNC(hTemp);
    f     := hTemp - I;

    p := V * (1.0 - S);
    q := V * (1.0 - (S * f));
    t := V * (1.0 - (S * (1.0 - f)));

    case I of
      0:
        begin
          R := V;
          G := t;
          B := p
        end;
      1:
        begin
          R := q;
          G := V;
          B := p
        end;
      2:
        begin
          R := p;
          G := V;
          B := t
        end;
      3:
        begin
          R := p;
          G := q;
          B := V
        end;
      4:
        begin
          R := t;
          G := p;
          B := V
        end;
      5:
        begin
          R := V;
          G := p;
          B := q
        end
    end
  end
end;

procedure ColorMap_Scanline(bmp: TBitmap; intValue: Integer);
var
  pColor    : PRGBQuad;
  I, J      : Integer;
  R, G, B   : byte;
  FR, FG, FB: Single;
  FH, FS, FV: Single;
begin
  FH    := intValue;
  FS    := 0;
  FV    := 0;
  for I := 0 to bmp.Height - 1 do
  begin
    pColor := bmp.ScanLine[I];
    for J  := 0 to bmp.Width - 1 do
    begin
      B  := pColor^.rgbBlue;
      G  := pColor^.rgbGreen;
      R  := pColor^.rgbRed;
      FR := R;
      FG := G;
      FB := B;
      RGBToHSV(FR, FG, FB, FH, FS, FV);
      FH := intValue;
      if FS = 0.0 then
        FH := 0;

      HSVtoRGB(FH, FS, FV, FR, FG, FB);
      pColor^.rgbRed   := Round(FR);
      pColor^.rgbGreen := Round(FG);
      pColor^.rgbBlue  := Round(FB);
      Inc(pColor);
    end;
  end;
end;

procedure ColorMap_Parallel_Proc(pColor: PRGBQuad; const bmpWidth, intValue: Integer);
var
  I         : Integer;
  R, G, B   : byte;
  FR, FG, FB: Single;
  FH, FS, FV: Single;
begin
  for I := 0 to bmpWidth - 1 do
  begin
    B  := pColor^.rgbBlue;
    G  := pColor^.rgbGreen;
    R  := pColor^.rgbRed;
    FR := R;
    FG := G;
    FB := B;
    RGBToHSV_Opt(FR, FG, FB, FH, FS, FV);
    FH := intValue;
    if FS = 0.0 then
      FH := 0;

    HSVtoRGB(FH, FS, FV, FR, FG, FB);
    pColor^.rgbRed   := Round(FR);
    pColor^.rgbGreen := Round(FG);
    pColor^.rgbBlue  := Round(FB);
    Inc(pColor);
  end;
end;

procedure ColorMap_Parallel(bmp: TBitmap; intValue: Integer);
var
  StartScanLine: Integer;
  bmpWidthBytes: Integer;
begin
  StartScanLine := Integer(bmp.ScanLine[0]);
  bmpWidthBytes := Integer(bmp.ScanLine[1]) - Integer(bmp.ScanLine[0]);

  TParallel.For(0, bmp.Height - 1,
    procedure(Y: Integer)
    var
      pColor: PRGBQuad;
    begin
      pColor := PRGBQuad(StartScanLine + Y * bmpWidthBytes);
      ColorMap_Parallel_Proc(pColor, bmp.Width, intValue);
    end);
end;

procedure ColorMap_SSEParallel_Proc(pColor: PRGBQuad; const intValue, bmpWidth: Integer);
asm
  {$IFDEF WIN64}
  XCHG    RAX,  RCX
  {$IFEND}
  MOVSS   XMM1, [c_PixBGRAMask]             // XMM1 = |00000000|00000000|00000000|000000FF|
  MOVD    XMM2, EDX                         // XMM2 = |000000000000000000000000000intValue|
  SHUFPS  XMM1, XMM1, 0                     // XMM1 = |000000FF|000000FF|000000FF|000000FF|
  SHUFPS  XMM2, XMM2, 0                     // XMM2 = |intValue|intValue|intValue|intValue|
  MOVAPS  XMM3, XMM1                        // XMM3 = |000000FF|000000FF|000000FF|000000FF|
  PSUBB   XMM3, XMM2                        // XMM3 = |000000FF - intValue|000000FF - intValue|000000FF - intValue|000000FF - intValue|

@LOOP:
  MOVUPS  XMM4, [EAX]                       // XMM4 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM5, XMM4                        // XMM5 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM6, XMM4                        // XMM6 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM7, XMM4                        // XMM7 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|

  // ��ȡ 4 �����ص� B3, B2, B1, B0
  ANDPS   XMM5, XMM1                        // XMM5 = |000000B3|000000B2|000000B1|000000B0|

  // ��ȡ 4 �����ص� G3, G2, G1, G0
  PSRLD   XMM6, 8                           // XMM6 = |00A3R3G3|00A2R2G2|00A1R1G1|00A0R0G0|
  ANDPS   XMM6, XMM1                        // XMM6 = |000000G3|000000G2|000000G1|000000G0|

  // ��ȡ 4 �����ص� R3, R2, R1, R0
  PSRLD   XMM7, 16                          // XMM7 = |0000A3R3|0000A2R2|0000A1R1|0000A0R0|
  ANDPS   XMM7, XMM1                        // XMM7 = |000000R3|000000R2|000000R1|000000R0|

  // ����ɫ��ģʽ

  // ���ؽ��
@RValue:
  PSLLD   XMM6, 8                           // XMM6  = |0000Y300|0000Y200|0000Y100|0000Y000|
  PSLLD   XMM7, 16                          // XMM7  = |00Y30000|00Y20000|00Y10000|00Y00000|
  ORPS    XMM5, XMM6                        // XMM5  = |0000Y3Y3|0000Y2Y2|0000Y1Y1|0000Y0Y0|
  ORPS    XMM5, XMM7                        // XMM5  = |00Y3Y3Y3|00Y2Y2Y2|00Y1Y1Y1|00Y0Y0Y0|
  MOVUPS  [EAX], XMM5                       // [EAX] = XMM5

  ADD     EAX, 16                           // pColor ��ַ�� 16��EAX ָ����4�����صĵ�ַ
  SUB     ECX, 4                            // Width �� 4, ÿ 4 ������һѭ��
  JNZ     @LOOP                             // ѭ��
end;

procedure ColorMap_SSEParallel(bmp: TBitmap; intValue: Integer);
var
  StartScanLine: Integer;
  bmpWidthBytes: Integer;
begin
  StartScanLine := Integer(bmp.ScanLine[0]);
  bmpWidthBytes := Integer(bmp.ScanLine[1]) - Integer(bmp.ScanLine[0]);

  TParallel.For(0, bmp.Height - 1,
    procedure(Y: Integer)
    var
      pColor: PRGBQuad;
    begin
      pColor := PRGBQuad(StartScanLine + Y * bmpWidthBytes);
      ColorMap_SSEParallel_Proc(pColor, intValue, bmp.Width);
    end);
end;

procedure ColorMap(bmp: TBitmap; const intColorMapValue: Integer; const cmt: TColorMapType = cmtSSEParallel);
begin
  case cmt of
    cmtScanline:
      ColorMap_Scanline(bmp, intColorMapValue);
    cmtParallel:
      ColorMap_Parallel(bmp, intColorMapValue);
    cmtSSEParallel:
      ColorMap_SSEParallel(bmp, intColorMapValue);
    cmtSSE2:
      ;
    cmtSSE4:
      ;
    cmtAVX1:
      ;
    cmtAVX2:
      ;
    cmtAVX512knl:
      ;
    cmtAVX512skx:
      ;
  end;
end;

end.