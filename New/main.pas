unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UnitSyntaxMemo, StdCtrls, ExtCtrls, XPMan, Buttons, ComCtrls,
  Menus;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    PopupMenu1: TPopupMenu;
    pumSet: TMenuItem;
    PopupMenu2: TPopupMenu;
    textPopup1: TMenuItem;
    MainMenu1: TMainMenu;
    mnuFile: TMenuItem;
    mnuOpen: TMenuItem;
    sep1: TMenuItem;
    mnuExit: TMenuItem;
    mnuEdit: TMenuItem;
    N6: TMenuItem;
    mnuView: TMenuItem;
    mnuAdditional: TMenuItem;
    mnuCursorPos: TMenuItem;
    mnuPageUpDown: TMenuItem;
    mnuNotSolidLines: TMenuItem;
    mnuSettings: TMenuItem;
    mnuPanning: TMenuItem;
    mnuHorPanning: TMenuItem;
    mnuReversePaning: TMenuItem;
    mnuHighlightLines: TMenuItem;
    pumClear: TMenuItem;
    pumDisabled: TMenuItem;
    StatusBar1: TStatusBar;
    mnuDebug: TMenuItem;
    mnuStepOver: TMenuItem;
    mnuStopDebug: TMenuItem;
    sep2: TMenuItem;
    mnuFreeMode: TMenuItem;
    mnuNeedPosibility: TMenuItem;
    ColorDialog1: TColorDialog;
    sep3: TMenuItem;
    mnuColors: TMenuItem;
    mnuBPEnabledBackColor: TMenuItem;
    mnuBPEnabledForeColor: TMenuItem;
    sep4: TMenuItem;
    mnuBPDisabledBackColor: TMenuItem;
    mnuBPDisabledForeColor: TMenuItem;
    sep5: TMenuItem;
    mnuDebugLineBackColor: TMenuItem;
    mnuDebugLineForeColor: TMenuItem;
    sep6: TMenuItem;
    mnuSelectedWordColor: TMenuItem;
    MPSyntaxMemo1: TMPSyntaxMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Memo1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MPSyntaxMemo1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure mnuCursorPosClick(Sender: TObject);
    procedure mnuPageUpDownClick(Sender: TObject);
    procedure mnuOpenClick(Sender: TObject);
    procedure mnuNotSolidLinesClick(Sender: TObject);
    procedure mnuPanningClick(Sender: TObject);
    procedure mnuHorPanningClick(Sender: TObject);
    procedure mnuReversePaningClick(Sender: TObject);
    procedure mnuHighlightLinesClick(Sender: TObject);
    procedure pumSetClick(Sender: TObject);
    procedure pumClearClick(Sender: TObject);
    procedure pumDisabledClick(Sender: TObject);
    procedure MPSyntaxMemo1BreakPointPopup(Sender: TObject;
      MousePos: TPoint; var Handled: Boolean);
    procedure mnuStepOverClick(Sender: TObject);
    procedure mnuStopDebugClick(Sender: TObject);
    procedure mnuFreeModeClick(Sender: TObject);
    procedure mnuNeedPosibilityClick(Sender: TObject);
    procedure mnuBPEnabledBackColorClick(Sender: TObject);
    procedure mnuBPEnabledForeColorClick(Sender: TObject);
    procedure mnuBPDisabledBackColorClick(Sender: TObject);
    procedure mnuBPDisabledForeColorClick(Sender: TObject);
    procedure mnuDebugLineBackColorClick(Sender: TObject);
    procedure mnuDebugLineForeColorClick(Sender: TObject);
    procedure mnuSelectedWordColorClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure MPSyntaxMemo1BeforeBreakPointChanged(Sender: TObject;
      const Row: Integer; const Action: TBPAction; var CanChange: Boolean);
    procedure MPSyntaxMemo1ParseWord(Sender: TObject; Word: String; Pos,
      Line: Integer; var Token: TToken);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  fCKeyWords: TStringList;

const
    tokKeyWord           = tokUser;
    tokType              = tokUser - 1;
    tokSpecType          = tokUser - 2;
    tokStructure         = tokUser - 3;

    tokBegin            = tokUser - 4;
    tokEnd              = tokUser - 5;


implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
MPSyntaxMemo1.Color:=clWindow;


fCKeyWords := TStringList.Create;
with fCKeyWords do begin
     Sorted:=False;

     AddObject('{', TObject(tokBegin));
     AddObject('}', TObject(tokEnd));

     AddObject('for', TObject(tokStructure));
     AddObject('continue', TObject(tokStructure));
     AddObject('break', TObject(tokStructure));
     AddObject('if', TObject(tokStructure));
     AddObject('else', TObject(tokStructure));
     AddObject('switch', TObject(tokStructure));
     AddObject('case', TObject(tokStructure));
     AddObject('default', TObject(tokStructure));
     AddObject('while', TObject(tokStructure));
     AddObject('do', TObject(tokStructure));
     AddObject('interrupt', TObject(tokStructure));
     AddObject('goto', TObject(tokStructure));

     AddObject('void', TObject(tokType));
     AddObject('char', TObject(tokType));
     AddObject('int', TObject(tokType));
     AddObject('short', TObject(tokType));
     AddObject('long', TObject(tokType));
     AddObject('signed', TObject(tokType));
     AddObject('unsigned', TObject(tokType));
     AddObject('enum', TObject(tokType));
     AddObject('union', TObject(tokType));
     AddObject('struct', TObject(tokType));
     AddObject('bit', TObject(tokType));
     AddObject('float', TObject(tokType));
     AddObject('double', TObject(tokType));
     AddObject('const', TObject(tokType));

     // �� ��������� - ��� ��������� ��� CodeVisionAVR
     // (��� ����������������, ���� ���-�� �� � �����)
     AddObject('eeprom', TObject(tokSpecType));
     AddObject('flash', TObject(tokSpecType));
     AddObject('register', TObject(tokSpecType));
     AddObject('static', TObject(tokSpecType));

     AddObject('inline', TObject(tokKeyWord));
     AddObject('extern', TObject(tokKeyWord));
     AddObject('funcused', TObject(tokKeyWord));
     AddObject('return', TObject(tokKeyWord));
     AddObject('sizeof', TObject(tokKeyWord));
     AddObject('typedef', TObject(tokKeyWord));
     AddObject('volatile', TObject(tokKeyWord));
     AddObject('sfrb', TObject(tokKeyWord));
     AddObject('sfrw', TObject(tokKeyWord));
     AddObject('NULL', TObject(tokKeyWord));

     AddObject('+', TObject(tokOperator));
     AddObject('++', TObject(tokOperator));
     AddObject('-', TObject(tokOperator));
     AddObject('--', TObject(tokOperator));
     AddObject('*', TObject(tokOperator));
     AddObject('/', TObject(tokOperator));
     AddObject('%', TObject(tokOperator));
     AddObject('=', TObject(tokOperator));
     AddObject('~', TObject(tokOperator));
     AddObject('!', TObject(tokOperator));
     AddObject('<', TObject(tokOperator));
     AddObject('>', TObject(tokOperator));
     AddObject('&', TObject(tokOperator));
     AddObject('&&', TObject(tokOperator));
     AddObject('|', TObject(tokOperator));
     AddObject('||', TObject(tokOperator));
     AddObject('^', TObject(tokOperator));
     AddObject('?', TObject(tokOperator));
     AddObject('<<', TObject(tokOperator));
     AddObject('>>', TObject(tokOperator));

     AddObject('=', TObject(tokOperator));
     AddObject('==', TObject(tokOperator));
     AddObject('!=', TObject(tokOperator));
     AddObject('>=', TObject(tokOperator));
     AddObject('<=', TObject(tokOperator));
     AddObject('+=', TObject(tokOperator));
     AddObject('-=', TObject(tokOperator));
     AddObject('*=', TObject(tokOperator));
     AddObject('/=', TObject(tokOperator));
     AddObject('%=', TObject(tokOperator));
     AddObject('&=', TObject(tokOperator));
     AddObject('^=', TObject(tokOperator));
     AddObject('|=', TObject(tokOperator));
     AddObject('>>=', TObject(tokOperator));
     AddObject('<<=', TObject(tokOperator));
     AddObject(',', TObject(tokOperator));

     AddObject('goto', TObject(tokErroneous2));

     Sort;
     Sorted:=False;
     end;

//��������� ��������� ����������
MPSyntaxMemo1.SyntaxAttributes.LoadFromFile(ExtractFilePath(paramstr(0))+'c.syn');

//��������� ���������, ���� �� ����
if FileExists(ExtractFilePath(paramstr(0))+'demo.c')
   then MPSyntaxMemo1.Lines.LoadFromFile(ExtractFilePath(paramstr(0))+'demo.c')
   else {}
        //�������� ����� ��������
        MPSyntaxMemo1.Lines.New;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
fCKeyWords.Destroy;
end;

// ����������� ���� ������ (C Keywords Analize)
procedure TForm1.MPSyntaxMemo1ParseWord(Sender: TObject; Word: String; Pos,
  Line: Integer; var Token: TToken);
var n: Integer;
begin
//��� ������ ������ - ���� �� ����� �������� �����
if fCKeyWords.Find(Word, n) then
   begin
   //���� ���� - �������� ��������� ��������� � ������������
   //(�������� �� ���������� �������)
   if Word=fCKeyWords.Strings[n]
      //���� ������� ���������� - ����������� �������������� �����
      then Token:=TToken(fCKeyWords.Objects[n])
      //���� �� ���������� - ����������� "���������" ����� - ���������� ������� ������
      //���� ����� ����������� ������� - tokErroneous2
      else Token:=tokErroneous;

   end;
end;

//��� �������� ������� ������ ����� �� ������������� � ������
function ShiftAsString(Shift: TShiftState): string;
    begin
        Result := '[';
        if ssShift  in Shift then Result := Result + ',ssShift';
        if ssAlt    in Shift then Result := ',ssAlt';
        if ssCtrl   in Shift then Result := Result + ',ssCtrl';
        if ssLeft   in Shift then Result := Result + ',ssLeft';
        if ssRight  in Shift then Result := Result + ',ssRight';
        if ssMiddle in Shift then Result := Result + ',ssMiddle';
        if ssDouble in Shift then Result := Result + ',ssDouble';
        if Length(Result) > 1 then System.Delete(Result, 2, 1);
        Result := Result + ']';
    end;


procedure TForm1.Memo1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
//���� ������ ��������� ������� �������
//self.Caption:=ShiftAsString(Shift)+' '+intToHex(Key,4);
end;

procedure TForm1.MPSyntaxMemo1BeforeBreakPointChanged(Sender: TObject;
  const Row: Integer; const Action: TBPAction; var CanChange: Boolean);
begin
//���� ����� ����������� ������ ������������ � ��
if Action=bpaSet
   then self.Caption:='���������� � ������ '+inttostr(Row)
   else self.Caption:='���� �� ������ '+inttostr(Row);{}
end;

procedure TForm1.MPSyntaxMemo1ContextPopup(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
begin
//���� ����� ��������� ��������� ���� ������
//self.Caption:='Context: '+intToStr(MousePos.X)+', '+intToStr(MousePos.Y);
end;


//������� ��� ������ ����...
procedure TForm1.mnuCursorPosClick(Sender: TObject);
begin
if smoShowCursorPos in MPSyntaxMemo1.Options
   then MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options-[smoShowCursorPos]
   else MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options+[smoShowCursorPos];
mnuCursorPos.Checked:=(smoShowCursorPos in MPSyntaxMemo1.Options);
end;

procedure TForm1.mnuPageUpDownClick(Sender: TObject);
begin
if smoShowPageScroll in MPSyntaxMemo1.Options
   then MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options-[smoShowPageScroll]
   else MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options+[smoShowPageScroll];
mnuPageUpDown.Checked:=(smoShowPageScroll in MPSyntaxMemo1.Options);
end;

procedure TForm1.mnuOpenClick(Sender: TObject);
var i,j,InFunc,start:integer;
    s:string;
begin
if OpenDialog1.Execute then
   begin
   MPSyntaxMemo1.Lines.LoadFromFile(OpenDialog1.FileName);
   //����� ����������� ������� �-���� ���������
   InFunc:=0;
   for i:=0 to MPSyntaxMemo1.Lines.Count-1 do
       begin
       s:=Trim(MPSyntaxMemo1.Lines.Strings[i]);
       for j:=1 to Length(s) do
           begin
           if s[j]='{'
              then begin
                   if InFunc=0
                      then begin
                           if j=1
                              then start:=i-1
                              else start:=i;
                           end;
                   inc(InFunc);
                   end;
           if s[j]='}'
              then begin
                   dec(InFunc);
                   if InFunc=0
                      then MPSyntaxMemo1.Sections.New(start,i,True);
                   end;
           end;
       end;

   end;
end;

procedure TForm1.mnuNotSolidLinesClick(Sender: TObject);
begin
if smoSolidSpecialLine in MPSyntaxMemo1.Options
   then MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options-[smoSolidSpecialLine]
   else MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options+[smoSolidSpecialLine];
mnuNotSolidLines.Checked:=not (smoSolidSpecialLine in MPSyntaxMemo1.Options);
end;

procedure TForm1.mnuPanningClick(Sender: TObject);
begin
if smoPanning in MPSyntaxMemo1.Options
   then MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options-[smoPanning]
   else MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options+[smoPanning];
mnuPanning.Checked:=(smoPanning in MPSyntaxMemo1.Options);
end;

procedure TForm1.mnuHorPanningClick(Sender: TObject);
begin
if smoHorPanning in MPSyntaxMemo1.Options
   then MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options-[smoHorPanning]
   else MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options+[smoHorPanning];
mnuHorPanning.Checked:=(smoHorPanning in MPSyntaxMemo1.Options);
end;

procedure TForm1.mnuReversePaningClick(Sender: TObject);
begin
if smoVerPanningReverse in MPSyntaxMemo1.Options
   then MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options-[smoVerPanningReverse]
   else MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options+[smoVerPanningReverse];
mnuReversePaning.Checked:=(smoVerPanningReverse in MPSyntaxMemo1.Options);
end;

procedure TForm1.mnuHighlightLinesClick(Sender: TObject);
begin
if smoHighlightLine in MPSyntaxMemo1.Options
   then MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options-[smoHighlightLine]
   else MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options+[smoHighlightLine];
mnuHighlightLines.Checked:=(smoHighlightLine in MPSyntaxMemo1.Options);
end;

procedure TForm1.pumSetClick(Sender: TObject);
begin
//IsBreakPoint - ���������� ���� �� �� ��������� ������ ��� ���.
//� ����������� �� ������ ������ �� ���� ���� ������� � ������������ ��������:
//���� ����������� ����� smoBreakPointsNeedPosibility �� ������ False ��� ��������
//������, ��� ��� �� Kind=bkPosible.
//��� ������� ��� ����, ����� �� ���������� ����� ��� �� �����, ����� ������:
//�������� ������������ �� ��� ���.
//���� ����� ������, ���������� ��� ��� ��� bkPosible - ����������� �������
// MPSyntaxMemo1.BreakPoints.IsPosible

MPSyntaxMemo1.BreakPoints.IsBreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP]:=True;

//���� ����� �������, ��� �� �� ������ ������ �� �������� �����������:
{MPSyntaxMemo1.BreakPoints.BreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP].Kind:=bkDisabled;{}
//�� ����� ������ ���������� ���� ��������� �� ����� ��� ���������.
end;

procedure TForm1.pumClearClick(Sender: TObject);
begin
//���� ���������� �� ���� ������ �����...
if MPSyntaxMemo1.BreakPoints.IsBreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP]
   then begin
        //... ������ ���.
        //� ����������� �� ������ - ��������� ������ ����� �������� �� �������.
        //� "��������� ������" (����� smoBreakPointsNeedPosibility ���������)
        //���������� �������� ��, � ������ "��������� �����������" (�����
        //��������) ���������� �������������� ������������ ���� �� �� Kind=bkPosible
        MPSyntaxMemo1.BreakPoints.IsBreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP]:=False;
        end;

end;

procedure TForm1.pumDisabledClick(Sender: TObject);
begin
//��������� ������� �� � ���� �� ����, ��...
if MPSyntaxMemo1.BreakPoints.IsBreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP]
   then begin
        // ��������� ��� ���, � ������ ������...
        if MPSyntaxMemo1.BreakPoints.BreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP].Kind=bkEnabled
           then MPSyntaxMemo1.BreakPoints.BreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP].Kind:=bkDisabled
           else MPSyntaxMemo1.BreakPoints.BreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP].Kind:=bkEnabled;
        end;

end;

procedure TForm1.MPSyntaxMemo1BreakPointPopup(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
begin

if  //���������, � ���� �� ����� ������ � ���������? ...
   (not MPSyntaxMemo1.Lines.IsValidLineIndex(MPSyntaxMemo1.BreakPoints.RowOfCurrentBP))
   //... ��� ����� �� �� ��������� ���� �� � ��������� ������
   or((smoBreakPointsNeedPosibility in MPSyntaxMemo1.Options)and(not MPSyntaxMemo1.BreakPoints.IsPosible[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP])){}
   //���� ��� - ��������� ����
   then begin
        Handled:=True;
        exit;
        end;

// ���� �� ��� ��� ���, �� ����������� ���������� ����, � ����������� �� ������� �� �� ���� ������
pumClear.Enabled:=MPSyntaxMemo1.BreakPoints.IsBreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP];
pumSet.Enabled:=not pumClear.Enabled;
pumDisabled.Enabled:=pumClear.Enabled;
pumDisabled.Checked:=False;
if pumDisabled.Enabled
   then pumDisabled.Checked:=MPSyntaxMemo1.BreakPoints.BreakPoint[MPSyntaxMemo1.BreakPoints.RowOfCurrentBP].Kind=bkDisabled;
end;

procedure TForm1.mnuStepOverClick(Sender: TObject);
begin
//������ ��������� ������ ���������
if MPSyntaxMemo1.Lines.IsValidLineIndex(MPSyntaxMemo1.StepDebugLine+1)
   then MPSyntaxMemo1.StepDebugLine:=MPSyntaxMemo1.StepDebugLine+1
   else MPSyntaxMemo1.StepDebugLine:=0;

end;

procedure TForm1.mnuStopDebugClick(Sender: TObject);
begin
//����������� ������ ���������
MPSyntaxMemo1.StepDebugLine:=-1;
end;

procedure TForm1.mnuFreeModeClick(Sender: TObject);
var i:integer;
begin
if not mnuFreeMode.Checked
   then begin
        // ����������� ����� ������ �� "���������"
        MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options-[smoBreakPointsNeedPosibility];
        //������� ��������� ��
        for i:=0 to MPSyntaxMemo1.Lines.Count-1 do
            MPSyntaxMemo1.BreakPoints.IsPosible[i]:=False;

        mnuFreeMode.Checked:=True;
        mnuNeedPosibility.Checked:=False;
        end;
end;

procedure TForm1.mnuNeedPosibilityClick(Sender: TObject);
var i:integer;
begin
if not mnuNeedPosibility.Checked
   then begin
        // ����������� ����� ������ �� "��������� �����������"
        MPSyntaxMemo1.Options:=MPSyntaxMemo1.Options+[smoBreakPointsNeedPosibility];

        for i:=0 to MPSyntaxMemo1.Lines.Count-1 do
            //��� ������ ������� - ��� ������ ����� ��������� ����������
            //� ������ ������ ���, ��� ������ �� ������
            if trim(MPSyntaxMemo1.Lines.Strings[i])<>''
               then MPSyntaxMemo1.BreakPoints.IsPosible[i]:=True
               else begin
                    //���� �� �� ���� ������ ��� - ������
                    MPSyntaxMemo1.BreakPoints.IsBreakPoint[i]:=False;
                    //�.�. � ������ smoBreakPointsNeedPosibility
                    //�������� �� �� ����� ���� �������� � ��� ������������
                    //�� ��� bkPosible, �� ������ "��������� ��", ��� ������ ��� ������������
                    MPSyntaxMemo1.BreakPoints.IsPosible[i]:=False;
                    //�������� ��� ������� ��������� ���������, �� ��� ����������
                    //����� ������ ������ ������� ���� ����� ������� (����������
                    //�� ��������� � ������ �� �� ����������� ���� - ��� �� ��
                    //������, � ����� �� ������� ��������.
                    end;

        mnuNeedPosibility.Checked:=True;
        mnuFreeMode.Checked:=False;
        end;
end;

//��������� ������ - ������������
procedure TForm1.mnuBPEnabledBackColorClick(Sender: TObject);
begin
ColorDialog1.Color:=MPSyntaxMemo1.BPEnabledBackColor;
if ColorDialog1.Execute
   then MPSyntaxMemo1.BPEnabledBackColor:=ColorDialog1.Color;
end;

procedure TForm1.mnuBPEnabledForeColorClick(Sender: TObject);
begin
ColorDialog1.Color:=MPSyntaxMemo1.BPEnabledForeColor;
if ColorDialog1.Execute
   then MPSyntaxMemo1.BPEnabledForeColor:=ColorDialog1.Color;

end;

procedure TForm1.mnuBPDisabledBackColorClick(Sender: TObject);
begin
ColorDialog1.Color:=MPSyntaxMemo1.BPDisabledBackColor;
if ColorDialog1.Execute
   then MPSyntaxMemo1.BPDisabledBackColor:=ColorDialog1.Color;
end;

procedure TForm1.mnuBPDisabledForeColorClick(Sender: TObject);
begin
ColorDialog1.Color:=MPSyntaxMemo1.BPDisabledForeColor;
if ColorDialog1.Execute
   then MPSyntaxMemo1.BPDisabledForeColor:=ColorDialog1.Color;
end;

procedure TForm1.mnuDebugLineBackColorClick(Sender: TObject);
begin
ColorDialog1.Color:=MPSyntaxMemo1.DebugLineBackColor;
if ColorDialog1.Execute
   then MPSyntaxMemo1.DebugLineForeColor:=ColorDialog1.Color;
end;

procedure TForm1.mnuDebugLineForeColorClick(Sender: TObject);
begin
ColorDialog1.Color:=MPSyntaxMemo1.DebugLineForeColor;
if ColorDialog1.Execute
   then MPSyntaxMemo1.DebugLineForeColor:=ColorDialog1.Color;
end;


procedure TForm1.mnuSelectedWordColorClick(Sender: TObject);
begin
ColorDialog1.Color:=MPSyntaxMemo1.SelectedWordColor;
if ColorDialog1.Execute
   then MPSyntaxMemo1.SelectedWordColor:=ColorDialog1.Color;
end;

procedure TForm1.mnuExitClick(Sender: TObject);
begin
Close;
end;



end.
