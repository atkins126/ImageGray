unit db.Image.GeometricTrans;
{
  Func: 32λλͼ���α任
  Name: dbyoung@sina.com
  Date: 2021-2-22
  Vers: Delphi 10.3.2
  Test: 4096 * 4096 * 32
  Note��Delphi �� Release ģʽ�����Ż��ģ�Debug ��û�еģ������ʱ�䣬������ DEBUG ģʽ�µ���ʱ��
  Note: ���г��򣬲����� IDE �����в鿴Ч������������ IDE ִ�в鿴Ч����
}

interface

uses Winapi.Windows, System.Threading, System.Classes, System.Math, Vcl.Graphics, db.Image.Common;

{ ˮƽ��ת ����ģʽ����Ҫ���� IDE ִ�� }
procedure HorizMirror(bmp: TBitmap);

{ ��ֱ��ת }
procedure VertiMirror(bmp: TBitmap);

{ ת�÷�ת ����ģʽ����Ҫ���� IDE ִ�� }
procedure HAndVMirror(bmp: TBitmap);

implementation

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
      K: DWORD;
      pColor01: PDWORD;
      pColor02: PDWORD;
    begin
      pColor01 := PDWORD(StartScanLine + Y * bmpWidthBytes);
      pColor02 := PDWORD(StartScanLine + Y * bmpWidthBytes);
      for X := 0 to bmp.Width div 2 - 1 do
      begin
        Inc(pColor02, bmp.Width - X - 1);
        K := pColor02^;
        pColor02^ := pColor01^;
        pColor01^ := K;
        Inc(pColor01);
        Dec(pColor02, bmp.Width - X - 1);
      end;
    end);
end;

{ ��ֱ��ת }
procedure VertiMirror(bmp: TBitmap);
var
  Count, Y: Integer;
  pColor01: PByte;
  pColor02: PByte;
  tmpColor: PByte;
begin
  Count    := Integer(bmp.ScanLine[0]) - Integer(bmp.ScanLine[1]);
  tmpColor := AllocMem(Count);
  try
    for Y := 0 to bmp.Height div 2 - 1 do
    begin
      pColor01 := bmp.ScanLine[Y];
      pColor02 := bmp.ScanLine[bmp.Height - Y - 1];
      Move(pColor01^, tmpColor^, Count);
      Move(pColor02^, pColor01^, Count);
      Move(tmpColor^, pColor02^, Count);
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

end.
