unit db.Image.Invert;
{
  Func: 32λλͼ��ɫ
  Name: dbyoung@sina.com
  Date: 2021-01-07
  Vers: Delphi 10.3.2
  Test: 4096 * 4096 * 32
  Note��Delphi �� Release ģʽ�����Ż��ģ�Debug ��û�еģ������ʱ�䣬������ DEBUG ģʽ�µ���ʱ��

  ����ԭ��
  R = 255 - R;
  G = 255 - G;
  B = 255 - B;
  ARGB = 16777215 - ARGB
}

interface

uses Winapi.Windows, System.Classes, System.SysUtils, System.StrUtils, {$IF CompilerVersion >= 24.0} System.Threading, {$IFEND} System.Diagnostics, System.SyncObjs, Vcl.Graphics, Winapi.GDIPOBJ, Winapi.GDIPAPI, db.Image.Common;

type
  TInvertType = (itDelphi, itASM, itMMX, itSSE, itAVX, itAVX2, itAVX512);

procedure Invert(bmp: TBitmap; const gt: TInvertType = itAVX);

implementation

{ 48 ms }
procedure Invert_Delphi(bmp: TBitmap);
var
  pColor  : PDWORD;
  I, Count: Integer;
begin
  pColor := GetBitsPointer(bmp);
  Count  := bmp.width * bmp.height;
  for I  := 0 to Count - 1 do
  begin
    pColor^ := not pColor^;
    Inc(pColor);
  end;
end;

procedure Invert_ASM_Proc(pColor: PRGBQuad; const Count: Integer); register;
asm
  MOV   ECX, EDX

@LOOP:
  NOT   [EAX]
  ADD   EAX, 4
  DEC   ECX
  JNZ   @LOOP
end;

{ 14 ms }
procedure Invert_ASM(bmp: TBitmap);
begin
  Invert_ASM_Proc(GetBitsPointer(bmp), bmp.width * bmp.height);
end;

procedure Invert_MMX_Proc(pColor: PByte; const Count: Integer); register;
asm
  MOV   ECX, EDX

@LOOP:
  PCMPEQD  MM0, MM0
  PSUBD    MM0, [EAX]
  MOVQ   [EAX], MM0

  ADD   EAX, 8
  SUB   ECX, 8
  JNZ   @LOOP

  EMMS
end;

{ 7 ms }
procedure Invert_MMX(bmp: TBitmap);
begin
  Invert_MMX_Proc(GetBitsPointer(bmp), bmp.width * bmp.height * 4);
end;

procedure Invert_SSE_Proc(pColor: PByte; const Count: Integer); register;
asm
  {$IFDEF WIN64}
  MOV   RAX, RCX
  {$IFEND}
  MOV   ECX, EDX

@LOOP:
  PCMPEQD  XMM0, XMM0
  PSUBD    XMM0, [EAX]
  MOVUPS  [EAX], XMM0

  ADD   EAX, 16
  SUB   ECX, 16
  JNZ   @LOOP
end;

{ 7 ms }
procedure Invert_SSE(bmp: TBitmap);
begin
  Invert_SSE_Proc(GetBitsPointer(bmp), bmp.width * bmp.height * 4);
end;

procedure Invert_AVX_proc(pColor: PByte; Count: Integer);
asm
  MOV ECX, EDX

  {$IFDEF FPC}
  VXORPS  XMM1, XMM1, XMM1
  VCMPPS  YMM1, YMM1, YMM1, 0
@LOOP:
  VMOVUPS YMM0, [EAX]
  VXORPS  YMM0, YMM0, YMM1
  VMOVDQU [EAX], YMM0
  {$ELSE}
  DB  $C5, $F0, $57, $C9
  DB  $C5, $F4, $C2, $C9, $00
@LOOP:
  DB  $C5, $FC, $10, $00
  DB  $C5, $FC, $57, $C1
  DB  $C5, $FE, $7F, $00
  {$ENDIF}

  ADD EAX, 32
  SUB ECX, 32
  JNZ @loop
end;

procedure Invert_AVX(bmp: TBitmap);
begin
  Invert_AVX_proc(GetBitsPointer(bmp), bmp.width * bmp.height * 4);
end;

procedure Invert(bmp: TBitmap; const gt: TInvertType = itAVX);
begin
  case gt of
    itDelphi:             //
      Invert_Delphi(bmp); // 42 ms
    itASM:                //
      Invert_ASM(bmp);    // 13 ms
    itMMX:                //
      Invert_MMX(bmp);    // 9 ms
    itSSE:                //
      Invert_SSE(bmp);    // 7 ms
    itAVX:                //
      Invert_AVX(bmp);    // 7 ms
    itAVX2:               //
      ;                   // 5 ms
    itAVX512:             //
      ;                   // 7 ms
  end;
end;

end.
