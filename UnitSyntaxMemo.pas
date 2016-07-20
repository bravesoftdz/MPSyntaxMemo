unit UnitSyntaxMemo;

interface

// {$DEFINE SYNDEBUG}

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls,
    Contnrs, Clipbrd;

const
    tokBlank        = 0;
    tokText         = 1;
    tokString       = 2;
    tokStringEnd    = 3;
    tokHexValue     = 4;
    tokInteger      = 5;
    tokFloat        = 6;
    tokILComment    = 7;
    tokMLCommentBeg = 8;
    tokMLCommentEnd = 9;
    tokELCommentBeg = 10;
    tokELCommentEnd = 11;
    tokEndLine      = 12;
    tokParenBeg     = 13;
    tokParenEnd     = 14;
    tokBrackedBeg   = 15;
    tokBracketEnd   = 16;
    tokOperator     = 17;
    tokPoint        = 18;
    tokComma        = 19;
    tokReference    = 20;
    tokDereference  = 21;
    tokReserved     = 22;
//    tokCustomDraw   = 23;
    tokUser         = 255;

 type
    TMPCustomSyntaxMemo = class;
    TMPSynMemoRange     = class;
    TMPSynMemoSection   = class;
    TMPSynMemoStrings   = class;
    TMPSyntaxParser     = class;
    TMPSyntaxAttributes = class;

    EMPSyntaxMemo       = class(Exception);

    // �����
    TToken              = tokBlank..tokUser;
    PToken              = ^TToken;
    TTokenSet           = set of TToken;
    TCharSet            = set of Char;

    // ����� �������
    TParseOption        = (poHasELComment, poHasMLComment, poHasILComment,
                           poHasHexPrefix, poFloatValid, poHasReference,
                           poHasDereference, poBLSeparated);
    TParseOptions       = set of TParseOption;

    // ���������������� ���������� ����������� ������ �����
    TUserTokenEvent     = procedure(
        Sender          : TObject;
        Word            : string;
        Pos, Line       : Integer;
        var Token       : TToken
    ) of object;

    // ��� - ������ �������� �������� �������� ������
    TCharWidths         = array [Boolean] of array [Char] of Byte;

    // �������� ����������� ��������� ������
    TTokenStyle         = record
                            tsForeground : TColor;          // ���� ������
                            tsBackground : TColor;          // ���� ����
                            tsStyle      : TFontStyles;     // ����� ������
                          end;

    // �����, ����������� ��������� ��������� � ����������� ���������� �������
    TMPSyntaxAttributes = class
    private
        fRichMemo       : TMPCustomSyntaxMemo;
        fLitString      : Char;
        fLitILComment   : string;
        fLitMLCommentB  : string;
        fLitMLCommentE  : string;
        fLitELCommentB  : string;
        fLitELCommentE  : string;
        fLitHexPrefix   : string;
        fLitDecimalPoint: Char;
        fLitReference   : Char;
        fLitDereference : Char;
        fParseOptions   : TParseOptions;
        fTokenStyles    : array [TToken] of TTokenStyle;
        fOnUserToken    : TUserTokenEvent;
        function        GetColor(const Token: TToken; const Index: Integer): TColor;
        function        GetStyle(const Token: TToken): TFontStyles;
        procedure       SetColor(const Token: TToken; const Index: Integer; const Value: TColor);
        procedure       SetStyle(const Token: TToken; const Value: TFontStyles);
    public
        constructor     Create(Owner: TMPCustomSyntaxMemo);
        procedure       Assign(Friend: TMPSyntaxAttributes);
        function        Equals(const T1, T2: TToken): Boolean;
        procedure       SaveToFile(const FileName: string);
        procedure       LoadFromFile(const FileName: string);
        procedure       CopyAttrs(const SrcToken: TToken; DstTokArray: array of TToken);
        property        LiteralString: Char read fLitString write fLitString;
        property        LiteralILComment: string read fLitILComment write fLitILComment;
        property        LiteralMLCommentBeg: string read fLitMLCommentB write fLitMLCommentB;
        property        LiteralMLCommentEnd: string read fLitMLCommentE write fLitMLCommentE;
        property        LiteralELCommentBeg: string read fLitELCommentB write fLitELCommentB;
        property        LiteralELCommentEnd: string read fLitELCommentE write fLitELCommentE;
        property        LiteralHexPrefix: string read fLitHexPrefix write fLitHexPrefix;
        property        LiteralDecimalPoint: Char read fLitDecimalPoint write fLitDecimalPoint;
        property        LiteralReference: Char read fLitReference write fLitReference;
        property        LiteralDereference: Char read fLitDereference write fLitDereference;
        property        ParseOptions: TParseOptions read fParseOptions write fParseOptions;
        property        OnUserToken: TUserTokenEvent read fOnUserToken write fOnUserToken;
        property        FontColor[const Token: TToken]: TColor index 0 read GetColor write SetColor;
        property        BackColor[const Token: TToken]: TColor index 1 read GetColor write SetColor;
        property        FontStyle[const Token: TToken]: TFontStyles read GetStyle write SetStyle;
    end;


    // ����� - �����
    // ��������� �����
    TMPSyntaxTokenStyle = ( stsInSelection,     // ����� ������ ���������
                            stsPressed          // ����� ��� ������� ���������� ���� - reserved for future use
                          );
    TMPSyntaxTokenStyles= set of TMPSyntaxTokenStyle;
    TMPSyntaxToken      = class
    public
        stStart         : Word;                     // ������ �����, ��������
        stLength        : Word;                     // ����� �����, ��������
        stToken         : TToken;                   // ��� (�����) �����
        stStyle         : TMPSyntaxTokenStyles;     // ����� ��������
    end;

    // �������������� ������ ������ /����� ����� ������ ������ ������/
    TMPSyntaxParser     = class (TObjectList)
    private
        fSection        : TMPSynMemoSection;
        fVisibleIndex   : Integer;
        fNeedReparse    : Boolean;
        function        GetToken(const TokIndex: Integer): TMPSyntaxToken;
        procedure       SetToken(const TokIndex: Integer; const Value: TMPSyntaxToken);
    protected
        function        ParseLine(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken; virtual;
        function        ParseLineEx(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken; virtual;
    public
        constructor     Create(const AsCloneOf: TMPSyntaxParser = nil);
        procedure       Assign(const Friend: TMPSyntaxParser);
        procedure       Clear; override;
        procedure       AddToken(const Beg, Len: Integer; Token: TToken);
        procedure       GroupTokens;
        procedure       SplitTokens(const sx, ex: Integer);
        function        AsString: string;
        function        LastToken: TToken;
        function        FirstToken: TToken;
        function        Parse(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
        property        Tokens[const TokIndex: Integer]: TMPSyntaxToken read GetToken write SetToken; default;
        property        NeedReparse: Boolean read fNeedReparse write fNeedReparse;
        property        Section: TMPSynMemoSection read fSection write fSection;
        property        VisibleIndex: Integer read fVisibleIndex write fVisibleIndex;
    end;


    { Max Proof Syntax Memo Strings Class }
    // ����� ������������� ���������� ����������� ������ � ��� �������������� ��������
    // � ������� ���������������� ������ TMPSyntaxParser, �� ���������� �������� �����
    // ������ ������ ������. ��� ��������� � ������ �������� � ���� ������������ override
    // ����������-����������: Put, Insert � Delete.
    TStringsStateItem   = (
                        ssTextChanged,      // ���� ���������� ������
                        ssSectionsChanged,  // ���� ���������� ������ (New, Explode)
                        ssNeedReIndex,      // ���� ���������� ������ (Expand, Collapse)
                        ssNeedReparseAll,   // ��������� ������ ��������� �����
                        ssUndoProcess       // � ������ ������ ������������ �����
    );
    TStringsState       = set of TStringsStateItem;

    TMPSynMemoStrings    = class(TStringList)
    private
        fRichMemo       : TMPCustomSyntaxMemo;              // ������
        fFileName       : string;                           // ��� �����
        fVirtualFileName: Boolean;                          // ��� ����� ������������� (�� ���������)
        fState          : TStringsState;                    // ����� ���������
        fModified       : Boolean;                          // ����� �������
        fDirectAccess   : Boolean;                          // ������ ������ � ������
        function        GetParser(const Row: Integer): TMPSyntaxParser;
        procedure       SetModified(const Value: Boolean);
        procedure       SetFileName(const Value: string);
    protected
        procedure       Changed; override;
        procedure       Put(Index: Integer; const s: string); override;
        procedure       SetUpdateState(Updating: Boolean); override;
        function        ParseLine(const Index: Integer; const TestNextLine: Boolean): Boolean; virtual;
        property        State: TStringsState read fState write fState;
    public
        constructor     Create(const Owner: TMPCustomSyntaxMemo);
        procedure       Clear; override;
        function        PositionToRC(Value: Integer): TPoint;
        function        RCToPosition(Col, Row: Integer): Integer;
        procedure       Parse(const EntireText : Boolean; const NeedRepaint: Boolean = False);
        procedure       Delete(Index: Integer); override;
        procedure       InsertItem(Index: Integer; const s: string; AObject: TObject); override;
        procedure       LoadFromStream(Stream: TStream); override;
        procedure       SaveToStream(Stream: TStream); override;
        procedure       LoadFromFile(const NewFileName: string); override;
        procedure       SaveToFile(const NewFileName: string); override;
        procedure       New; virtual;
        function        IsValidLineIndex(const Row: Integer): Boolean;
        property        FileName: string read fFileName write SetFileName;
        property        Parser[const Row: Integer]: TMPSyntaxParser read GetParser;
        property        VirtualFileName: Boolean read fVirtualFileName;
        property        Modified: Boolean read fModified write SetModified;
        property        DirectAccess: Boolean read fDirectAccess write fDirectAccess;
        property        UpdateCount;
    end;


    // ����� "������ �����"
    // ����� ������� ������ � ����� (������ �����), ������ � ����� ������
    // ����� "�������������" ������ ���� ������, ������� ����� ������
    TMPSynMemoSection    = class(TObjectList)
    private
        fParent         : TMPSynMemoSection;    // ������ - ��������
        fRowBeg         : Integer;              // ������ ��������� ����� ��������
        fRowEnd         : Integer;              // ����� ��������� ����� ��������
        fLevel          : Integer;              // ������� ����������� ������
        fCollapsed      : Boolean;              // ������� ����, ��� ������ ��������
        function        GetSections(const Idx: Integer): TMPSynMemoSection;
        procedure       SetLevel(const Value: Integer);
    public
        constructor     Create;
        property        RowBeg: Integer read fRowBeg write fRowBeg;
        property        RowEnd: Integer read fRowEnd write fRowEnd;
        property        Sections[const Idx: Integer]: TMPSynMemoSection read GetSections; default;
        property        Level: Integer read fLevel write SetLevel;
        property        Parent: TMPSynMemoSection read fParent write fParent;
        property        Collapsed: Boolean read fCollapsed write fCollapsed;
    end;

    TMPSMSectionClone   = class(TMPSynMemoSection)
    private
        fRefCount       : Integer;
    protected
        procedure       AddRef;
        procedure       Release;
    public
        property        RefCount: Integer read fRefCount;
    end;

    // Section Manager Class
    TSectionMark = (smNone, smExpanded, smCollapsed, smEnd);

    // ����� - �������� ������.
    // ������������ ���������� ��������������� �������� � �������� (��������, ����������, �������, ��������� � �.�.)
    // �� ������������ �����.
    TMPSynMemoSections   = class(TObject)
    private
        fRichMemo       : TMPCustomSyntaxMemo;          // ������
        fRoot           : TMPSMSectionClone;            // �������� ������
        fIndexes        : TList;                        // ���������� ������ ��� �������� ������� � �������� ��������
        fMaxLevel       : Integer;                      // ������������ ������� ����������� ������
        fMaxExpandLevel : Integer;                      // ������������ �������� ������� ����������� ������
        fErrorLine      : Integer;                      // ������ ������ ������ � ���������� ���������� ��������
        fErrorString    : string;                       // ������ ���������� ��������
        procedure       ReIndex;
        procedure       MakeUnique;
        procedure       SetRoot(const Value: TMPSMSectionClone);
        function        GetSection(const Row: Integer): TMPSynMemoSection;
        procedure       SetSection(const Row: Integer; Value: TMPSynMemoSection);
    protected
        procedure       Scan; virtual;
        procedure       FillOutput(const Sl: TStringList); virtual;
        procedure       DeleteRow(const Row: Integer); virtual;
        procedure       InsertRow(const Row: Integer); virtual;
    public
        class function  DetectSectionMark(const s: string): TSectionMark;
        constructor     Create(Owner: TMPCustomSyntaxMemo);
        destructor      Destroy; override;
        function        New(const Row1, Row2: Integer; const IsCollapsed: Boolean = False): TMPSynMemoSection;
        procedure       Explode(const Row: Integer; const Recursive: Boolean);
        procedure       Collapse(const Row: Integer; const Recursive, SafeSelf: Boolean);
        procedure       Expand(const Row: Integer; const Recursive, ParentRecursive: Boolean);
        function        SectionBorder(const Row: Integer): TSectionMark;
        function        AsText: string;
        function        Next(Sec: TMPSynMemoSection): TMPSynMemoSection;
        function        Prev(Sec: TMPSynMemoSection): TMPSynMemoSection;
        function        Visible(const Sec: TMPSynMemoSection): Boolean;
        property        Section[const Row: Integer]: TMPSynMemoSection read GetSection write SetSection;
        property        MaxLevel: Integer read fMaxLevel;
        property        ErrorLine: Integer read fErrorLine;
        property        ErrorString: string read fErrorString;
        property        EntireSection: TMPSMSectionClone read fRoot write SetRoot;
        property        Indexes: TList read fIndexes;
    end;


    // Range Class
    TMPSynMemoUndoItem  = class
        uiCaretPos      : TPoint;
        uiSelStart      : TPoint;
        uiSelEnd        : TPoint;
        uiSealing       : Boolean;
        uiText          : string;
        uiSections      : TMPSMSectionClone;
        destructor      Destroy; override;
    end;

    // TMPSynMemoRange
    // ����� �������� ���������� ����� ������� �������������� �������
    // T..Strings, T..Sections � ��������� ������������. �������� ������ -
    // - �������������� �������� ��� �������� ������� (PosY, PosX) �
    // ��������� ��� ��������� (Strings, Sections), � ����� �����������
    // ����������� ������ �������� ������������ (��������� ����� ������)
    TMPSynMemoRange = class(TObject)
    private
        fRichMemo       : TMPCustomSyntaxMemo;  // ��������
        fStart          : TPoint;               // ������ ���������� �������
        fEnd            : TPoint;               // ����� ���������� �������
        fPos            : TPoint;               // ������� ���������� ������� ������������ ������ [Row,Col]
        fSealing        : Boolean;              // ����� Collapsed (���������, ������ ���������)
        fMaxUndoDepth   : Integer;              // ������������ ������ ����� ������
        fUndoStack      : TObjectList;          // ���� ������
        function        GetLength: Integer;
        function        GetPosition: Integer;
        function        GetText: string;
        function        GetMarkedText: string;
        procedure       CutFinalSpaces(const Row: Integer);
        procedure       SetLength(const Value: Integer);
        procedure       SetMaxUndoDepth(const Value: Integer);
        procedure       SetPosition(const Value: Integer);
        procedure       SetPos(const NewPos: TPoint);
        procedure       SetRange(const Index, Value: Integer);
        procedure       SetText(const Value: string);
        procedure       SetMarkedText(Value: string);
    protected
        function        AddUndo(const UndoText: string = ''): TMPSynMemoUndoItem;
        property        StartX : Integer read fStart.X write fStart.X;
        property        StartY : Integer read fStart.Y write fStart.Y;
        property        EndX   : Integer read fEnd.X   write fEnd.X;
        property        EndY   : Integer read fEnd.Y   write fEnd.Y;
    public
        constructor     Create(Owner: TMPCustomSyntaxMemo);
        destructor      Destroy; override;
        procedure       Collapse;
        procedure       Enlarge(const Value: Integer; const EnlargeLine: Boolean = False; const VisiblesOnly: Boolean = False);
        procedure       Delete;
        { �������� ��� �������� }
        procedure       CreateSection;
        procedure       ExplodeSection(const Recursive: Boolean);
        procedure       ExpandSection(const Recursive: Boolean);
        procedure       CollapseSection(const Recursive: Boolean);
        procedure       GotoSection(const GoForward: Boolean);
        { ��������� ������ ������ }
        procedure       CopyToClipboard;
        procedure       CutToClipBoard;
        procedure       PasteFromClipboard;
        { ���� ������ }
        procedure       DoUndo;
        procedure       ClearUndo;
        procedure       SelectAll;
        procedure       SelectFromStart;
        procedure       SelectToEnd;
        function        IsEmpty: Boolean;
        function        CanUndo: Boolean;
        property        UndoStack: TObjectList read fUndoStack;
        property        PosX   : Integer index 0 read fPos.X write SetRange;
        property        PosY   : Integer index 1 read fPos.Y write SetRange;
        property        Pos: TPoint read fPos write SetPos;
        property        MaxUndoDepth: Integer read fMaxUndoDepth write SetMaxUndoDepth default 100;
        property        Position:     Integer read GetPosition write SetPosition;
        property        SelLength:    Integer read GetLength write SetLength;
        property        Text: string read GetText write SetText;
        property        MarkedText: string read GetMarkedText write SetMarkedText;
    end;

    TWordInfoEvent      = procedure (Sender: TMPCustomSyntaxMemo; const X, Y, WordIndex, Row: Integer; Showing: Boolean) of object;
    //TDrawWordEvent      = procedure (Sender: TMPCustomSyntaxMemo; ACanvas: TCanvas; Rect: TRect; Row, Index: Integer) of object;
    TRowIndexConvertionDirection = (cdNeedReal, cdNeedScreen);
    // ����� ���������
    TMPSynMemoOption = (smoShowFileNameInTabSheet,      // ���������� ��� ����� �� ��������
                        smoShowFileNameInFormCaption,   // ���������� ��� ����� � �����
                        smoReadOnly,                    // ������ ��������� ������ (����� ������)
                        smoOverwrite,                   // ����� ������ ��������
                        smoSkipSectionsOnCopy,          // �� ���������� � ����� ������ ���������� � �������
                        smoSkipSectionsOnPaste,         // �� ��������������� ������ ��� ������� ������ �� ������ ������
                        smoAutoGutterWidth,             // ������ ������� ������� �� �������� ������
                        smoWriteMarkersOnSave,          // ��� ���������� ������ �������� ������� ������
                        smoVSNET_SectionsStyle          // ����� �������� ������ ��� � Visual Studio NET
    );
    TMPSynMemoOptions   = set of TMPSynMemoOption;
    TLogEvent           = procedure (Sender: TObject; LogStr: string) of object;
    TChangedItem        = (ciText, ciSelection, ciSections, ciUndoStack, ciOptions);
    TChangedItems       = set of TChangedItem;
    TMPChangeEvent      = procedure (Sender: TObject; ChangedItems: TChangedItems) of object;


    // ����������� ����������
    TBookmarkIndex      = 0..9;
    TMPBookmarkManager    = class
    private
        fRichMemo       : TMPCustomSyntaxMemo;
        fBookMarks      : array [TBookmarkIndex] of Integer;
        fImages         : TBitmap;
        function        GetBookMarks(const Index: TBookmarkIndex): Integer;
        procedure       SetBookMarks(const Index: TBookmarkIndex; const Row: Integer);
    public
        constructor     Create(Owner: TMPCustomSyntaxMemo);
        destructor      Destroy; override;
        function        Find(const Row: Integer; var Index: TBookmarkIndex): Boolean;
        procedure       Clear;
        procedure       PaintAt(const ACanvas: TCanvas; const x, y: Integer; const Index: TBookmarkIndex);
        property        BookMarks[const Index: TBookmarkIndex]: Integer read GetBookMarks write SetBookMarks; default;
    end;


    TMPCustomSyntaxMemo = class(TCustomControl)
    private
        fLines          : TMPSynMemoStrings;
        fRange          : TMPSynMemoRange;
        fSections       : TMPSynMemoSections;
        fOptions        : TMPSynMemoOptions;
        fBuffer         : TBitmap;
        fCharHeight     : Integer;
        fCharWidths     : TCharWidths;
        fParseAttributes: TMPSyntaxAttributes;
        fBookMarks      : TMPBookmarkManager;
        fOffsets        : TPoint;
        fDown           : Boolean;
        fPanning        : Boolean;
        fHinting        : Boolean;
        fPanStartPoint  : TPoint;
        fInsertMode     : Boolean;
        fVScroll        : TScrollBar;
        fHScroll        : TScrollBar;
        fSelColor       : TColor;
        fDefBackColor   : TColor;
        fDefForeColor   : TColor;
        fSelWord        : TPoint;
        fCaretVisible   : Boolean;
        fScreenLines    : array of Boolean;
        fGutterWidth    : Integer;
        fSectionIndent  : Integer;
        fChangesSummator: TChangedItems;
        {$IFDEF SYNDEBUG}
        fLogDisabled    : Boolean;
        {$ENDIF}
        fOnChange       : TMPChangeEvent;
        fOnWordInfo     : TWordInfoEvent;
//        fOnDrawWord     : TDrawWordEvent;
        fOnLog          : TLogEvent;
        { Gets }
        function        GetUserTokenEvent: TUserTokenEvent;
        { Sets }
        procedure       SetDefColor(const Index: Integer; const Value: TColor);
        procedure       SetGutterWidth(const Value: Integer);
        procedure       SetOffset(const Index, Value: Integer);
        procedure       SetOffsets(NewOffsets: TPoint);
        procedure       SetOptions(const Value: TMPSynMemoOptions);
        procedure       SetSectionIndent(const Value: Integer);
        procedure       SetSelColor(const Value: TColor);
        procedure       SetSelectedWord(const Value: TPoint);
        procedure       SetUserTokenEvent(const Value: TUserTokenEvent);
        { Others }
        procedure       Reset; virtual;
        procedure       CalcScreenParams;
        procedure       ScrollEnter(Sender: TObject);
        procedure       UpdateScrollBars;
        function        ClientLines: Integer;
        function        FindNextWord(var wx, wy: Integer): Boolean;
        function        FindPrevWord(var wx, wy: Integer): Boolean;
        procedure       ScrollClick(Sender: TObject);
        procedure       PaintGutter(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
        procedure       PaintSectionMarks(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
        procedure       PaintDots(const ACanvas: TCanvas);
        procedure       PaintTokens(const ACanvas: TCanvas; s: string; Sp: TMPSyntaxParser; TextIndent, SelStart, SelEnd: Integer);
//        procedure       PaintLine(const ScreenRow, Row: Integer);
        procedure       PaintLineEx3(const ScreenRow, Row: Integer);
        function        RowIndexConvert(const Index: Integer; const Direction: TRowIndexConvertionDirection): Integer;
        function        FindVisibleRow(const Row, Delta: Integer; const EnsureInRange: Boolean): Integer;
        function        RangeRowToScreenRow(const Row: Integer): Integer;
        { Repaint manager }
        procedure       ReDraw;
        procedure       NeedRedraw(const Row: Integer);
        procedure       NeedReDrawLE(const Row: Integer);
        procedure       NeedRedrawAll;
        { ���������� ��������� }
        function        CharPosToPixOffset(const Col, Row: Integer): Integer; overload;
        function        CharPosToPixOffset(const Col: Integer; s: string; Sp: TMPSyntaxParser): Integer; overload;
        function        PixOffsetToCharPos(const Pix, Row: Integer; const WordIndex: PInteger = nil): Integer;
        procedure       WndOffsetToPixOffset(OfsPoint: TPoint; var CharPix, Row: Integer; const TextRow: Boolean);
        function        PixOffsetToWndOffsetEx(const CharPix, ScreenRow: Integer): TPoint;
        function        GetSectionButtonRect(const ScreenRow, ALevel: Integer): TRect;
        function        IsLineVisible(const Row: Integer; const PScreenRow: PInteger = nil): Boolean;
        function        GetWndRect(const ScreenRow, Index: Integer): TRect;
        {$IFDEF SYNDEBUG}
        procedure       Log(const LogString: string);
        procedure       LogFmt(const LogFormat: string; LogArgs: array of const);
        {$ENDIF}
    protected
        function        CanResize(var NewWidth, NewHeight: Integer): Boolean; override;
        procedure       CreateParams(var Params: TCreateParams); override;
        procedure       WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
        procedure       WMSize(var Message: TMessage); message WM_SIZE;
        procedure       WMKillFocus(var Msg: TWMKillFocus); message WM_KILLFOCUS;
        procedure       WMLButtonDblClk(var Message: TWMMouse); message WM_LBUTTONDBLCLK;
        procedure       WMSetFocus(var Msg: TWMSetFocus); message WM_SETFOCUS;
        procedure       WMMouseWheel(var Message: TMessage); message WM_MouseWheel;
        procedure       MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
        procedure       MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
        procedure       MouseMove(Shift: TShiftState; X, Y: Integer); override;
        procedure       KeyDown(var Key: Word; Shift: TShiftState); override;
        procedure       KeyPress(var Key: Char); override;
        procedure       KeyUp(var Key: Word; Shift: TShiftState); override;
        procedure       FontChange(Sender: TObject);
        procedure       Paint; override;
        procedure       HideCaret;
        procedure       ShowCaret;
        procedure       Change(const ChangedItems: TChangedItems); virtual;
                        // ���������� ����������� ��������� ������ ������
        property        EntireRowRect[const ScreenRow: Integer]: TRect      index 0 read GetWndRect;
        property        TextRowRect[const ScreenRow: Integer]: TRect        index 1 read GetWndRect;
        property        EntireGutterRect[const ScreenRow: Integer]: TRect   index 2 read GetWndRect;
        property        SymbolsGutterRect[const ScreenRow: Integer]: TRect  index 3 read GetWndRect;
    public
        constructor     Create(AOwner: TComponent); override;
        destructor      Destroy; override;
        function        CharPosToWordIndex(const Col, Row: Integer): Integer;
        function        GetWordAtPos(const X, Y: Integer; var WordIndex, Row: Integer): Boolean;
        procedure       ShowWord(const Row, WordIndex: Integer);
        procedure       MakeVisible(const Col, Row: Integer; const Length: Integer = 1);
        procedure       Navigate(const Col, Row: Integer);
        { Properties }
        property        BookMarks: TMPBookmarkManager read fBookMarks;
        property        DefBackColor: TColor index 0 read fDefBackColor write SetDefColor default clWindow;
        property        DefForeColor: TColor index 1 read fDefForeColor write SetDefColor default clBlack;
        property        GutterWidth: Integer read fGutterWidth write SetGutterWidth default 32;
        property        Lines: TMPSynMemoStrings read fLines;
        property        OffsetXPix: Integer index 0 read fOffsets.X write SetOffset;
        property        OffsetY: Integer index 1 read fOffsets.Y write SetOffset;
        property        Offsets: TPoint read fOffsets write SetOffsets;
        property        Range: TMPSynMemoRange read fRange;
        property        SectionIndent: Integer read fSectionIndent write SetSectionIndent default 16;
        property        Sections: TMPSynMemoSections read fSections;
        property        SelColor: TColor read fSelColor write SetSelColor default clSkyBlue;
        property        SelectedWord: TPoint read fSelWord write SetSelectedWord;
        property        SyntaxAttributes: TMPSyntaxAttributes read fParseAttributes;
        property        Options: TMPSynMemoOptions read fOptions write SetOptions;
        property        OnChange: TMPChangeEvent read fOnChange write fOnChange;
//        property        OnDrawWord: TDrawWordEvent read fOnDrawWord write fOnDrawWord;
        property        OnWordInfo: TWordInfoEvent read fOnWordInfo write fOnWordInfo;
        property        OnParseWord: TUserTokenEvent read GetUserTokenEvent write SetUserTokenEvent;
        property        OnLog: TLogEvent read fOnLog write fOnLog;
    end;


    TMPSyntaxMemo       = class(TMPCustomSyntaxMemo)
    published
        property        Anchors;
        property        Align;
        property        Color;
        property        DefBackColor;
        property        DefForeColor;
        property        GutterWidth default 32;
        property        Font;
        property        Options;
        property        SelColor default clHighlight;
        property        SectionIndent default 32;
        property        TabStop default True;
        property        OnKeyDown;
        property        OnKeyPress;
        property        OnMouseDown;
        property        OnMouseMove;
        property        OnMouseUp;
        property        OnClick;
        property        OnContextPopup;
        property        OnDblClick;
        property        OnDragDrop;
        property        OnChange;
//        property        OnDrawWord;
        property        OnWordInfo;
        property        OnParseWord;
        property        OnLog;
    end;

const SectionMarks      : array [TSectionMark] of string = ('', '{<+}', '{<-}', '{>>}');

      SECTION_HEADER_LENGTH = 4;

implementation

{$R SyntaxMemo.res}

uses Forms, StrUtils, Math, Types, ComCtrls;

var CF_SYNTAX: THandle;

// Results of RangeRowToScreenRow()
const
    ROW_ABOVE_SCREEN    = -1;
    ROW_HIDEN           = -2;
    ROW_BELOW_SCREEN    = -3;

procedure Swap(var A, B: Integer);
var t: Integer;
begin
    t := A;
    A := B;
    B := t;
end;


// Class TParseAttributes Implementation

// � � � � � � � � � � �
constructor TMPSyntaxAttributes.Create(Owner: TMPCustomSyntaxMemo);
var T: TToken;
begin
    inherited Create;
    fRichMemo := Owner;
    // ������� ������� ������
    for T := Low(TToken) to High(TToken) do
        with fTokenStyles[T] do begin
            tsForeground    := clDefault;
            tsBackground    := clDefault;
            tsStyle         := [];
        end;
    // ����� �� ���������
    fLitString        := '''';
    fLitILComment     := '//';
    fLitMLCommentB    := '{';
    fLitMLCommentE    := '}';
    fLitELCommentB    := '(*';
    fLitELCommentE    := '*)';
    fLitHexPrefix     := '$';
    fLitDecimalPoint  := '.';
    fLitReference     := '@';
    fLitDereference   := '^';
    fParseOptions     := [  poHasELComment, poHasMLComment, poHasILComment,
                            poHasHexPrefix, poFloatValid, poHasReference,
                            poHasDereference  ];
    fTokenStyles[tokString].tsForeground        := clMaroon;
    fTokenStyles[tokString].tsStyle             := [fsItalic, fsUnderline];
    fTokenStyles[tokStringEnd].tsForeground     := clMaroon;
    fTokenStyles[tokStringEnd].tsStyle          := [fsItalic, fsUnderline];
    fTokenStyles[tokHexValue].tsForeground      := clNavy;
    fTokenStyles[tokHexValue].tsStyle           := [fsBold];
    fTokenStyles[tokInteger].tsForeground       := clNavy;
    fTokenStyles[tokFloat].tsForeground         := clNavy;
    fTokenStyles[tokFloat].tsStyle              := [fsItalic];
    fTokenStyles[tokILComment].tsForeground     := clGreen;
    fTokenStyles[tokMLCommentBeg].tsForeground  := clNavy;
    fTokenStyles[tokMLCommentBeg].tsBackground  := clMoneyGreen;
    fTokenStyles[tokMLCommentEnd].tsForeground  := clNavy;
    fTokenStyles[tokMLCommentEnd].tsBackground  := clMoneyGreen;
    fTokenStyles[tokELCommentBeg].tsForeground  := clNavy;
    fTokenStyles[tokELCommentBeg].tsBackground  := clMoneyGreen;
    fTokenStyles[tokELCommentEnd].tsForeground  := clNavy;
    fTokenStyles[tokELCommentEnd].tsBackground  := clMoneyGreen;
    fTokenStyles[tokParenBeg].tsForeground      := clBlue;
    fTokenStyles[tokParenEnd].tsForeground      := clBlue;
    fTokenStyles[tokBrackedBeg].tsForeground    := clBlue;
    fTokenStyles[tokBracketEnd].tsForeground    := clBlue;
end;


// ����������� ���� ��� ��������� ������������
procedure TMPSyntaxAttributes.Assign(Friend: TMPSyntaxAttributes);
begin
    if (self = Friend) or (Friend = nil) then Exit;
    fRichMemo.Lines.BeginUpdate;
    fLitString       := Friend.fLitString;
    fLitILComment    := Friend.fLitILComment;
    fLitMLCommentB   := Friend.fLitMLCommentB;
    fLitMLCommentE   := Friend.fLitMLCommentE;
    fLitELCommentB   := Friend.fLitELCommentB;
    fLitELCommentE   := Friend.fLitELCommentE;
    fLitHexPrefix    := Friend.fLitHexPrefix;
    fLitDecimalPoint := Friend.fLitDecimalPoint;
    fLitReference    := Friend.fLitReference;
    fLitDereference  := Friend.fLitDereference;
    fParseOptions    := Friend.fParseOptions;
    Move(Friend.fTokenStyles, fTokenStyles, SizeOf(fTokenStyles));
    fRichMemo.Lines.State := fRichMemo.Lines.State + [ssNeedReparseAll];
    fRichMemo.Lines.EndUpdate;
end;


// ���������� ������, ���� ���������� �������� ������� ���������
function TMPSyntaxAttributes.Equals(const T1, T2: TToken): Boolean;
begin
    Result := (fTokenStyles[T1].tsForeground = fTokenStyles[T2].tsForeground)
          and (fTokenStyles[T1].tsBackground = fTokenStyles[T2].tsBackground)
          and (fTokenStyles[T1].tsStyle = fTokenStyles[T2].tsStyle);
end;


// ���������� ������� ����� ������
function TMPSyntaxAttributes.GetColor(const Token: TToken; const Index: Integer): TColor;
begin
    if Index = 0
        then Result := fTokenStyles[Token].tsForeground
        else Result := fTokenStyles[Token].tsBackground;
end;


// ���������� ������� ����� ������ ������
function TMPSyntaxAttributes.GetStyle(const Token: TToken): TFontStyles;
begin
    Result := fTokenStyles[Token].tsStyle;
end;


// ������������� ������� ����� ������
procedure TMPSyntaxAttributes.SetColor(const Token: TToken; const Index: Integer; const Value: TColor);
begin
    if Index = 0
        then fTokenStyles[Token].tsForeground := Value
        else fTokenStyles[Token].tsBackground := Value;
end;


// ������������� ������� ����� ������ ������
procedure TMPSyntaxAttributes.SetStyle(const Token: TToken; const Value: TFontStyles);
begin
    fTokenStyles[Token].tsStyle := Value;
end;


// �������� �������� ������ SrcToken �� ��� ������ �� ������ DstTokArray
procedure TMPSyntaxAttributes.CopyAttrs(const SrcToken: TToken; DstTokArray: array of TToken);
var T: TToken;
begin
    for T := Low(DstTokArray) to High(DstTokArray) do
        fTokenStyles[DstTokArray[T]] := fTokenStyles[SrcToken];
end;


const
    bools: array[Boolean] of string = ('N', 'Y');
    CURRENT_SYN_VERSION = '1.0';
    SSynVersion         = 'SyntaxVersion';
    SLitString          = 'LitString';
    SLitILComment       = 'LitILComment';
    SLitMLCommentB      = 'LitMLCommentB';
    SLitMLCommentE      = 'LitMLCommentE';
    SLitELCommentB      = 'LitELCommentB';
    SLitELCommentE      = 'LitELCommentE';
    SLitHexPrefix       = 'LitHexPrefix';
    SLitDecimalPoint    = 'LitDecimalPoint';
    SLitReference       = 'LitReference';
    SLitDereference     = 'LitDereference';
    SForeground         = 'Fore';
    SBackground         = 'Back';
    SStyleBold          = 'Bold';
    SStyleUnderline     = 'ULin';
    SStyleItalic        = 'Ital';
    SPOHasELComment     = 'HasELComment';
    SPOHasMLComment     = 'HasMLComment';
    SPOHasILComment     = 'HasILComment';
    SPOHasHexPrefix     = 'HasHexPrefix';
    SPOValidFloat       = 'ValidFloat';
    SPOHasReference     = 'HasReference';
    SPOHasDereference   = 'HasDereference';
    SPOBLSeparated      = 'BLSeparated';


// ��������� ��������� �� �����
procedure TMPSyntaxAttributes.LoadFromFile(const FileName: string);
var T: TToken;
    {}
    function FirstChar(s: string): char;
    begin
        if s = '' then Result := #0 else Result := s[1];
    end;
    {}
begin
    with TStringList.Create do begin
        fRichMemo.Lines.BeginUpdate;
        try
            LoadFromFile(FileName);
            if Values[SSynVersion] <> CURRENT_SYN_VERSION then
                raise Exception.Create('������������ ������ ����������');
            fLitString          := FirstChar( Values[SLitString] );
            fLitILComment       := Values[SLitILComment];
            fLitMLCommentB      := Values[SLitMLCommentB];
            fLitMLCommentE      := Values[SLitMLCommentE];
            fLitELCommentB      := Values[SLitELCommentB];
            fLitELCommentE      := Values[SLitELCommentE];
            fLitHexPrefix       := Values[SLitHexPrefix];
            fLitDecimalPoint    := FirstChar( Values[SLitDecimalPoint] );
            fLitReference       := FirstChar( Values[SLitReference] );
            fLitDereference     := FirstChar( Values[SLitDereference] );

            fParseOptions := [];
            if Values[SPOHasELComment]   = bools[True] then Include(fParseOptions, poHasELComment);
            if Values[SPOHasMLComment]   = bools[True] then Include(fParseOptions, poHasMLComment);
            if Values[SPOHasILComment]   = bools[True] then Include(fParseOptions, poHasILComment);
            if Values[SPOHasHexPrefix]   = bools[True] then Include(fParseOptions, poHasHexPrefix);
            if Values[SPOValidFloat]     = bools[True] then Include(fParseOptions, poFloatValid);
            if Values[SPOHasReference]   = bools[True] then Include(fParseOptions, poHasReference);
            if Values[SPOHasDereference] = bools[True] then Include(fParseOptions, poHasDereference);
            if Values[SPOBLSeparated]    = bools[True] then Include(fParseOptions, poBLSeparated);

            for T := Low(TToken) to High(TToken) do
                with fTokenStyles[T] do begin
                    tsForeground := StrToIntDef(Values[SForeground + IntToStr(Ord(T))], clDefault);
                    tsBackground := StrToIntDef(Values[SBackground + IntToStr(Ord(T))], clDefault);
                    tsStyle := [];
                    if Values[SStyleBold + IntToStr(Ord(T))] = bools[True] then Include(tsStyle, fsBold);
                    if Values[SStyleUnderline + IntToStr(Ord(T))] = bools[True] then Include(tsStyle, fsUnderline);
                    if Values[SStyleItalic + IntToStr(Ord(T))] = bools[True] then Include(tsStyle, fsItalic);
                end;

            fRichMemo.Lines.State := fRichMemo.Lines.State + [ssNeedReparseAll];
        finally
            fRichMemo.Lines.EndUpdate;
            Free;
        end
    end;
end;


// ��������� ��������� � ����
procedure TMPSyntaxAttributes.SaveToFile(const FileName: string);
var T: TToken;
begin
    with TStringList.Create do begin
        Values[SSynVersion]       := CURRENT_SYN_VERSION;

        Values[SLitString]        := fLitString;
        Values[SLitILComment]     := fLitILComment;
        Values[SLitMLCommentB]    := fLitMLCommentB;
        Values[SLitMLCommentE]    := fLitMLCommentE;
        Values[SLitELCommentB]    := fLitELCommentB;
        Values[SLitELCommentE]    := fLitELCommentE;
        Values[SLitHexPrefix]     := fLitHexPrefix;
        Values[SLitDecimalPoint]  := fLitDecimalPoint;
        Values[SLitReference]     := fLitReference;
        Values[SLitDereference]   := fLitDereference;

        Values[SPOHasELComment]   := bools[poHasELComment in fParseOptions];
        Values[SPOHasMLComment]   := bools[poHasMLComment in fParseOptions];
        Values[SPOHasILComment]   := bools[poHasILComment in fParseOptions];
        Values[SPOHasHexPrefix]   := bools[poHasHexPrefix in fParseOptions];
        Values[SPOValidFloat]     := bools[poFloatValid in fParseOptions];
        Values[SPOHasReference]   := bools[poHasReference in fParseOptions];
        Values[SPOHasDereference] := bools[poHasDereference in fParseOptions];
        Values[SPOBLSeparated]    := bools[poBLSeparated in fParseOptions];

        for T := Low(TToken) to High(TToken) do
            with fTokenStyles[T] do begin
                if tsForeground <> clDefault then
                    Values[SForeground + IntToStr(Ord(T))] := IntToStr(tsForeground);
                if tsForeground <> clDefault then
                    Values[SBackground + IntToStr(Ord(T))] := IntToStr(tsBackground);
                if fsBold in fTokenStyles[T].tsStyle then
                    Values[SStyleBold + IntToStr(Ord(T))] := bools[True];
                if fsUnderline in fTokenStyles[T].tsStyle then
                    Values[SStyleUnderline + IntToStr(Ord(T))] := bools[True];
                if fsItalic in fTokenStyles[T].tsStyle then
                    Values[SStyleItalic + IntToStr(Ord(T))] := bools[True];
            end;

        try
            SaveToFile(FileName);
        finally
            Free;
        end;
    end;
end;



// CLASS TMPSyntaxParser Implementation

const

    TokenStrings: array [tokBlank..tokReserved] of string = (
        'tokBlank',     'tokText',    'tokString',    'tokStringEnd',    'tokHexValue',    'tokInteger',
        'tokFloat',    'tokILComment',    'tokMLCommentBeg',    'tokMLCommentEnd',    'tokELCommentBeg',
        'tokELCommentEnd',    'tokEndLine',    'tokParenBeg',    'tokParenEnd',    'tokBrackedBeg',
        'tokBracketEnd',    'tokOperator',    'tokPoint',    'tokComma',    'tokReference',
        'tokDereference', 'tokReserved');

    TOKEN_USER = 'tokUser#';


// ������� ���� ������������� �������
constructor TMPSyntaxParser.Create(const AsCloneOf: TMPSyntaxParser = nil);
begin
    inherited Create(True);
    if Assigned(AsCloneOf) then
        Assign(AsCloneOf);
end;


// ��������� ������� ������ (0-based), ����� � ����� �����
procedure TMPSyntaxParser.AddToken(const Beg, Len: Integer; Token: TToken);
var W: TMPSyntaxToken;
begin
    W := TMPSyntaxToken.Create;
    W.stStart := Word(Beg - 1);
    W.stLength := Word(Len);
    W.stToken := Token;
    W.stStyle := [];
    Add(W);
end;


// ���������� �������� �����
function TMPSyntaxParser.GetToken(const TokIndex: Integer): TMPSyntaxToken;
begin
    Result := TMPSyntaxToken( inherited Items[TokIndex] );
end;


// ������������� �������� �����
procedure TMPSyntaxParser.SetToken(const TokIndex: Integer; const Value: TMPSyntaxToken);
begin
    Items[TokIndex] := Value;
end;


// ���������� "�������" ���� ������ (��� �������)
function TMPSyntaxParser.AsString: string;
var i: Integer;
    s: string;
    T: TMPSyntaxToken;
begin
    Result := '';
    for i := 0 to Count - 1 do begin
        T := Tokens[i];
        if T.stToken > tokReserved
            then s := TOKEN_USER + IntToHex(T.stToken, 2) + 'H'
            else s := TokenStrings[T.stToken];
        Result := Result + #13#10 + s + #9'Beg=' + IntToStr(T.stStart) + #9'Len=' + IntToStr(T.stLength);
    end;
end;


// ��������� ������
procedure TMPSyntaxParser.Assign(const Friend: TMPSyntaxParser);
var i: Integer;
    T, NewT: TMPSyntaxToken;
begin
    Clear;
    for i := 0 to Friend.Count - 1 do begin
        T := Friend.Tokens[i];
        NewT := TMPSyntaxToken.Create;
        NewT.stStart    := T.stStart;
        NewT.stLength   := T.stLength;
        NewT.stToken    := T.stToken;
        NewT.stStyle    := T.stStyle;
        ADd(NewT);
    end;
    fSection      := Friend.Section;
    fVisibleIndex := Friend.VisibleIndex;
    fNeedReparse  := Friend.NeedReparse;
end;


// ������� ���������� � ������
procedure TMPSyntaxParser.Clear;
begin
    inherited Clear;
    fNeedReparse := False;
end;


// ���������� ������� ������ (tokString-tokStringEnd � �.�.)
// �������� �����������.
procedure TMPSyntaxParser.GroupTokens;
var wi: Integer;
    {}
    procedure GroupSame(var i: Integer; SameTokens: TTokenSet);
    var W, W1: TMPSyntaxToken;
    begin
        W := Tokens[i];
        Inc(i);
        while i < Count do begin
            W1 := Tokens[i];
            if not (W1.stToken in SameTokens) then Break;
            W.stLength := W1.stStart + W1.stLength - W.stStart;
            W.stToken := W1.stToken;
            Delete(i);
        end;
    end;
begin
    if Count < 2 then Exit;
    wi := 0;
    while wi < Count do begin
        case GetToken(wi).stToken of
        tokString:
            GroupSame(wi, [tokString, tokStringEnd]);

        tokMLCommentBeg:
            GroupSame(wi, [tokMLCommentBeg, tokMLCommentEnd]);

        tokELCommentBeg:
            GroupSame(wi, [tokELCommentBeg, tokELCommentEnd]);

        tokILComment:
            GroupSame(wi, [tokILComment]);
        else
            Inc(wi);
        end;
    end;
end;


// ��������� ������, ������ �� ��������� ��������� ���������
// ���� sx < 0, �� ������ �������� � ������ ������ (�� ������ ������ ������� ���������)
// ���� ex = MAXINT, �� ������ �������� �� ����� ������ (�� ��������� ������ ������� ���������)
// �������� �����������.
procedure TMPSyntaxParser.SplitTokens(const sx, ex: Integer);
var wi: Integer;
    T: TMPSyntaxToken;
    {}
    function TestSel(const r: Integer): Boolean;
    var TT: TMPSyntaxToken;
    begin
        with T do begin
            Result := InRange(r, stStart + 1, stStart + stLength - 1);
            if Result then begin
                // ��������� ������� �� ���
                TT := TMPSyntaxToken.Create;
                TT.stStart  := r;
                TT.stLength := stStart + stLength - r;
                TT.stToken  := stToken;
                stLength := r - stStart;
                Insert(wi + 1, TT);
            end
        end
    end;
begin
    wi := 0;
    while wi < Count do begin
        T := Tokens[wi];
        if not TestSel(sx)
            then TestSel(ex);
        if InRange(T.stStart, sx, ex - 1)
            then Include(T.stStyle, stsInSelection)
            else Exclude(T.stStyle, stsInSelection);
        Inc(wi);
    end;
end;


// ���������� ������ ����� ������ (���� �� ���� - ����� tokText)
function TMPSyntaxParser.FirstToken: TToken;
begin
    if Count > 0
        then Result := Tokens[0].stToken
        else Result := tokText;
end;


// ���������� ��������� ����� ������ (...)
function TMPSyntaxParser.LastToken: TToken;
begin
    if Count > 0
        then Result := Tokens[Count - 1].stToken
        else Result := tokText;
end;


// �������� - ���������� �������������� ������ ������ (������)
function TMPSyntaxParser.Parse(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
begin
    if poBLSeparated in PA.ParseOptions
        then Result := ParseLine(Line, LineIndex, LastToken, PA)
        else Result := ParseLineEx(Line, LineIndex, LastToken, PA);
    fNeedReparse := False;
end;


// ParseLine() �������������� ������ ������ �� �������, ������������ ���������
function TMPSyntaxParser.ParseLine(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
var si: string;
    i, wordbeg: Integer;
    InWord, InLit: Boolean;
    {}
    function HasChars(const s: string; StartPos: Integer; Chars: TCharSet): Boolean;
    var i: Integer;
    begin
        Result := False;
        for i := StartPos to Length(s) do
            if not (s[i] in Chars) then
                Exit;
        Result := True;
    end;
    {}
begin
    Clear;
    InWord := False;
    InLit  := False;
    WordBeg := 1;

    Result := tokText;
    if Length(Line) = 0 then Exit;
    if Line[Length(Line)] >= ' ' then
        Line := Line + ' ';

    for i := 1 to Length(Line) do

        if Line[i] > ' ' then begin
            // ������ ������
            if not InWord then
                WordBeg := i;
            InWord := True;
        end else begin

            // Blank symbol
            if InWord then begin
                si := Copy(Line, WordBeg, i - wordbeg);

                Result := LastToken;

                { Test for comments begin }
                if not (Result in [tokMLCommentBeg, tokELCommentBeg]) then begin
                    if  (poHasELComment in PA.ParseOptions)
                    and (Pos(PA.LiteralELCommentBeg, si) = 1) then
                        Result := tokELCommentBeg
                    else
                    if  (poHasMLComment in PA.ParseOptions)
                    and (Pos(PA.LiteralMLCommentBeg, si) = 1) then
                        Result := tokMLCommentBeg
                    else
                    if  (poHasILComment in PA.ParseOptions)
                    and (Pos(PA.LiteralILComment, si) = 1) then
                        Result := tokILComment
                end;

                { Test for comments end }
                case Result of
                tokILComment:   ;   // �������� �� ����� ������

                tokMLCommentBeg:
                    with PA do
                        if RightStr(si, Length(LiteralMLCommentEnd)) = LiteralMLCommentEnd
                            then Result := tokMLCommentEnd;

                tokELCommentBeg:
                    with PA do
                        if RightStr(si, Length(PA.LiteralELCommentEnd)) = LiteralELCommentEnd
                            then Result := tokELCommentEnd;

                else
                    // ������������ � ������ �� ���������
                    Result := tokText;

                    { Test for string begin }
                    if si[1] = PA.LiteralString then
                        InLit := True;
                    { Test for string end }
                    if InLit then begin
                        Result := tokStringEnd;
                        if si[Length(si)] = PA.LiteralString then
                            InLit := False;
                    end else

                    { Numbers: separately Integer, Hex or Float values }
                    if (Length(si) > Length(PA.LiteralHexPrefix))
                    and (Pos(PA.LiteralHexPrefix, si) = 1)
                    and HasChars(si, Length(PA.LiteralHexPrefix) + 1, ['0'..'9','A'..'F','a'..'f']) then
                        Result := tokHexValue
                    else
                    if (Length(si) > 1) and (si[1] in ['-', '0'..'9']) then begin
                        if HasChars(si, 2, ['0'..'9']) then
                            Result := tokInteger
                        else
                        if HasChars(si, 2, ['0'..'9', PA.LiteralDecimalPoint]) then
                            Result := tokFloat
                    end;

                end;

                { User tokens }
                if Result = tokText then     // ���������� ������� ����������
                    if Assigned(PA.OnUserToken) then
                        PA.OnUserToken(self, si, WordBeg, LineIndex, Result);

                // Add to processed words list
                AddToken(WordBeg, i - WordBeg, Result);
                LastToken := Result;
            end;
            InWord := False;
        end;

    // �������������� ����������� ������ ����������� � ����� ������
    // ����� ������������ ��������� ������ ������
    // (����� ������ �������� ������������� �����������)
    if not (Result in [tokMLCommentBeg, tokELCommentBeg]) then
        Result := tokText;
end;


// �������������� ������ ������ "�����������"
function TMPSyntaxParser.ParseLineEx(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
const
    HexChars            : TCharSet = ['0'..'9','A'..'F','a'..'f'];
    IntChars            : TCharSet = ['0'..'9'];
    { ���������� ��������� ������� � ������ }
type TCharRange = (crBlank, crSymbol, crLetter, crLit);
    function CharRange(c: Char): TCharRange;
    begin
        if c = PA.LiteralString then
            Result := crLit
        else
            case c of
            #$00..#$20: Result := crBlank;
            #$21..#$2F,
            #$3A..#$40: Result := crSymbol;
            #$30..#$39,
            #$41..#$FF: Result := crLetter;
            else        Result := crSymbol;
            end;
    end;

    // ���������� ������� ����, ��� �������� ���� �������
    function CharRangeChange(c1, c2: Char): Boolean;
    begin
        Result := CharRange(c1) <> CharRange(c2);
    end;

    // �������� �� ������ �����������
    function TestCommentsBegin(const Pos: Integer; var Token: TToken): Boolean;
    begin
        Result := True;
        if  (poHasELComment in PA.ParseOptions)
        and (PosEx(PA.LiteralELCommentBeg, Line, Pos) = Pos) then
            Token := tokELCommentBeg
        else
        if  (poHasMLComment in PA.ParseOptions)
        and (PosEx(PA.LiteralMLCommentBeg, Line, Pos) = Pos) then
            Token := tokMLCommentBeg
        else
        if  (poHasILComment in PA.ParseOptions)
        and (PosEx(PA.LiteralILComment, Line, Pos) = Pos) then
            Token := tokILComment
        else
            Result := False;
    end;

    // ���������� ������� ����, ��� ����� �������� ������������
    function InComment(const Token: TToken): Boolean;
    begin
        Result := Token in [tokELCommentBeg, tokMLCommentBeg, tokILComment];
    end;

    // ������������ �����������, ������� � ��������� ������� (Pos)
    // ���������� ������� ���������� �� ������ ����������� ������� (Pos)
    // ��� ����������� �������� ����� Token, ���� �� ������ ���������
    // ������������ �����
    procedure ProcessComments(var Pos: Integer; var Token: TToken);
    var WordBeg: Integer;
        si: string;
        InWord: Boolean;
    begin
        si := '';
        InWord := True;
        WordBeg := Pos;
        while Pos <= Length(Line) do begin
            if Line[Pos] > ' ' then begin
                if not InWord then
                    WordBeg := Pos;
                InWord := True;
                si := si + Line[Pos];
                // �������� �� ����� �����������
                case Token of
                tokMLCommentBeg:
                    if RightStr(si, Length(PA.LiteralMLCommentEnd)) = PA.LiteralMLCommentEnd then begin
                        Token := tokMLCommentEnd;
                        Inc(Pos);
                        AddToken(WordBeg, Pos - WordBeg, Token);
                        Exit;
                    end;
                tokELCommentBeg:
                    if RightStr(si, Length(PA.LiteralELCommentEnd)) = PA.LiteralELCommentEnd then begin
                        Token := tokELCommentEnd;
                        Inc(Pos);
                        AddToken(WordBeg, Pos - WordBeg, Token);
                        Exit;
                    end;
                end;
            end else
            if InWord then begin
                InWord := False;
                AddToken(WordBeg, Pos - WordBeg, Token);
                si := '';
            end;
            Inc(Pos);
        end;
    end;

    // ������������ ������, ������� � ��������� �������, ��� ��� Line[Pos] = fLitString
    // ���������� ������� ���������� �� ������ ������ �������
    procedure ProcessString(var Pos: Integer);
    var WordBeg: Integer;
        InWord: Boolean;
    begin
        InWord := True;
        WordBeg := Pos;
        Inc(Pos);
        while Pos <= Length(Line) do begin
            if Line[Pos] > ' ' then begin
                if not InWord then
                    WordBeg := Pos;
                InWord := True;
                // �������� �� ����� ������
                if Line[Pos] = PA.LiteralString then begin
                    Inc(Pos);
                    AddToken(WordBeg, Pos - WordBeg, tokStringEnd);
                    Exit;
                end;
            end else
            if InWord then begin
                InWord := False;
                AddToken(WordBeg, Pos - WordBeg, tokString);
            end;
            Inc(Pos);
        end;
    end;

    // ������������ ����������������� �����, ������� � ��������� �������,
    // ��� ��� Line[Pos] = fLitHexPrefix
    // ���������� ������� ���������� �� ������ ����� �������
    procedure ProcessHexValue(var Pos: Integer);
    var WordBeg: Integer;
    begin
        WordBeg := Pos;
        repeat
            Inc(Pos);
        until (Pos > Length(Line)) or not (Line[Pos] in HexChars);
        AddToken(WordBeg, Pos - WordBeg, tokHexValue);
    end;

    // ������������ ����� ��� ������� �����, ������� � ��������� �������,
    // ��� ��� Line[Pos] in IntChars
    // ���������� ������� ���������� �� ������ ����� �������
    procedure ProcessNumber(var Pos: Integer);
    var Token: TToken;
        WordBeg: Integer;
        ValidChars: TCharSet;
    begin
        Token := tokInteger;
        ValidChars := IntChars + [PA.LiteralDecimalPoint];
        WordBeg := Pos;
        repeat
            Inc(Pos);
            if Line[Pos] = PA.LiteralDecimalPoint then
                if Token = tokInteger
                    then Token := tokFloat
                    else Break;
        until (Pos > Length(Line)) or not (Line[Pos] in ValidChars);
        AddToken(WordBeg, Pos - WordBeg, Token);
    end;

    // ������������ �����
    procedure ProcessWord(var s: string; StartPos: Integer);
    var Token: TToken;
    begin
        if Length(s) = 0 then Exit;
        Token := tokText;

        // User event
        if Assigned(PA.OnUserToken) then
            PA.OnUserToken(self, s, StartPos, LineIndex, Token);

        AddToken(StartPos, Length(s), Token);
        s := '';
    end;

    function IsCharAlphaNumeric(c: Char): Boolean;
    begin
        Result := Windows.IsCharAlphaNumeric(c) or (c = '_');
    end;

var Word: string;
    Col, WordBeg: Integer;
    c: Char;
begin
    Clear;
    Result := LastToken;
    if (Length(Line) = 0) or (PA = nil) then Exit;
    if Line[Length(Line)] >= ' ' then
        Line := Line + ' ';
    Word := '';
    WordBeg := 1;

    Col := 1;
    while Col <= Length(Line) do begin

        // Next char
        c := Line[Col];

        // ����� ������������ �������� � ������������� �����������
        if InComment(Result) or TestCommentsBegin(Col, Result) then begin
            ProcessWord(Word, WordBeg);
            ProcessComments(Col, Result);
        end else

        // Strings supply
        if c = PA.LiteralString then begin
            ProcessWord(Word, WordBeg);
            ProcessString(Col);
        end else

        // Numbers supply: Hex
        if (poHasHexPrefix in PA.ParseOptions)
        and (PosEx(PA.LiteralHexPrefix, Line, Col) = Col) then begin
            ProcessWord(Word, WordBeg);
            ProcessHexValue(Col);
        end else

        // Numbers supply: Integer and Float
        if (c in IntChars)
        and ((Col = 1) or not IsCharAlphaNumeric(Line[Col-1])) then begin
            ProcessWord(Word, WordBeg);
            ProcessNumber(Col);
        end else

        begin
            Result := tokText;
            case c of
            '.':    Result := tokPoint;
            ',':    Result := tokComma;
            ';':    Result := tokEndLine;
            '(':    Result := tokParenBeg;
            ')':    Result := tokParenEnd;
            '[':    Result := tokBrackedBeg;
            ']':    Result := tokBracketEnd;
            else
                if (poHasReference in PA.ParseOptions)
                and (c = PA.LiteralReference) then
                    Result := tokReference
                else
                if (poHasDereference in PA.ParseOptions)
                and (c = PA.LiteralDereference) then
                    Result := tokDereference;
            end;
            if Result <> tokText then begin
                ProcessWord(Word, WordBeg);
                AddToken(Col, 1, Result);
            end else

            {.. Some other tokens here ..}

            begin
                if c <= ' ' then begin
                    ProcessWord(Word, WordBeg)
                end else
                if Length(Word) = 0 then begin
                    Word := c;
                    WordBeg := Col;
                end else
                if CharRangeChange(c, Word[Length(Word)]) then begin
                    ProcessWord(Word, WordBeg);
                    Word := c;
                    WordBeg := Col;
                end else
                    Word := Word + c;
            end;

            Inc(Col);
        end;
    end;
end;


// Class TMPSynMemoStrings methods implementation

var GlobalUntitledIndex: Integer = 1;
const UNTITLEDFN = 'Untitled';


// Create() �����������
constructor TMPSynMemoStrings.Create(const Owner: TMPCustomSyntaxMemo);
begin
    inherited Create;
    fRichMemo   := Owner;
    fState      := [];
    FileName    := UNTITLEDFN + IntToStr(GlobalUntitledIndex) + '.txt';
    Inc(GlobalUntitledIndex);
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Strings.Create');
    {$ENDIF}
end;


// Clear() ������� �����������, ������ �������� �������
procedure TMPSynMemoStrings.Clear;
var i: Integer;
    Da: Boolean;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.Clear {');
    {} {$ENDIF}
    BeginUpdate;
    // ��������� ������� ����� � ������������� ����� ������� ������� � ������
    Da := fDirectAccess;
    fDirectAccess := True;
    // ������� ��� ������
    for i := Count - 1 downto 0 do
        Objects[i].Free;
    inherited Clear;
    fRichMemo.Sections.Scan;
    fRichMemo.Reset;
    // ��������������� �����
    fDirectAccess := Da;
    fState := fState + [ssNeedReparseAll, ssNeedReIndex];
    SetModified(True);
    EndUpdate;
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('} Strings.Clear');
    {} {$ENDIF}
end;


// ����������� ������ �� ������ ����� � �������� ������ � ������� � ���
function TMPSynMemoStrings.PositionToRC(Value: Integer): TPoint;
var i: Integer;
begin
    for i := 0 to Count - 1 do
        if Value < Length(Get(i)) + 2 then begin
            Result := Point(Value, i);
            Exit;
        end else
            Dec(Value, Length(Get(i)) + 2);
    Result.Y := Count - 1;
    Result.X := Length(Get(Result.Y));
end;


// ����������� �������� ������� � �������� ������ � ��� ������ �� ������ ������
function TMPSynMemoStrings.RCToPosition(Col, Row: Integer): Integer;
var i: Integer;
begin
    Result := 0;
    for i := 0 to Row - 1 do
        Inc(Result, Length(Get(i)) + 2);
    Inc(Result, Col);
end;


// ������������� ���������� �������� ������
procedure TMPSynMemoStrings.Put(Index: Integer; const s: string);
begin
    if fDirectAccess then
        inherited Put(Index, s)
    else begin
        BeginUpdate;
        // �������� ������
        inherited Put(Index, s);
        // �������� ������ ��� ������������
        Parser[Index].NeedReparse := True;
        Include(fState, ssTextChanged);
        // Ÿ ���� ��������������, ���� ��� �����, �������,
        // �� ��� ������ ����������������, ��������� ������ ��� �����
        // ������� ��� ����������
        { fRichMemo.NeedRedraw(Index); }
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Strings.Put(%d, "%s")', [Index, s]);
        {} {$ENDIF}
        EndUpdate;
    end;
end;


// ��������� ������ ����� ��������
procedure TMPSynMemoStrings.InsertItem(Index: Integer; const s: string; AObject: TObject);
begin
    if fDirectAccess then
        inherited InsertItem(Index, s, TMPSyntaxParser.Create)
    else begin
        BeginUpdate;
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Strings.Insert(%d, "%s") {', [Index, s]);
        {} {$ENDIF}
        // ��������� ������
        inherited InsertItem(Index, s, TMPSyntaxParser.Create);
        // �������� ������ ��� ������������
        Parser[Index].NeedReparse := True;
        Include(fState, ssTextChanged);
        // ������������ ������, ���� ��� �� �����, �������
        if not (ssUndoProcess in fState) then
            fRichMemo.Sections.InsertRow(Index);
        { TODO : ��� �� ������ ���.. �������������� ����� ������ ������ ���� ���� }
        // ��� ���������� ������ ������ �������������� ���� �����
        fRichMemo.NeedRedrawLE(Index);
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('} Strings.Insert');
        {} {$ENDIF}
        EndUpdate;
    end;
end;


// ������� �������� ������
procedure TMPSynMemoStrings.Delete(Index: Integer);
begin
    if DirectAccess then
        inherited Delete(Index)
    else begin
        BeginUpdate;
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Strings.Delete(%d) {', [Index]);
        {} {$ENDIF}
        // ������������ ������, ���� ��� �� �����
        if not (ssUndoProcess in fState) then
            fRichMemo.Sections.DeleteRow(Index);
        // ����������� StringParser ���� ������
        if Assigned(Objects[Index]) then
            Objects[Index].Free;
        // ������� ������
        inherited Delete(Index);
        // ������, ������ �� � �����, ����� �������� �� ���������
        Parser[Index].NeedReparse := True;
        Include(fState, ssTextChanged);
        { TODO : ��� �� ������ ���.. �������������� ����� ������ ������ ���� ���� }
        // ��� �������� ������ ������ �������������� ���� �����
        fRichMemo.NeedReDrawLE(Index);
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('} Strings.Delete');
        {} {$ENDIF}
        EndUpdate;
    end;
end;


// ������������� ���� ��������� - ��������
procedure TMPSynMemoStrings.Changed;
begin
end;


// SetUpdateState() ��������� �������� ����������
procedure TMPSynMemoStrings.SetUpdateState(Updating: Boolean);
begin
    inherited;
    if Updating then begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('BeginUpdate {');
        {} {$ENDIF}

        fRichMemo.HideCaret;
        fState := fState - [ssTextChanged, ssSectionsChanged, ssNeedReIndex, ssNeedReparseAll];
        fRichMemo.Change([]);

    end else begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('} EndUpdate');
        {} {$ENDIF}

        // ���� ������ ��������, ������������� ��������� ���������
        if fState * [ssTextChanged, ssSectionsChanged] <> [] then
            SetModified(True);

        // ���� ����������, ������ ����������� ������� �����
        if ssNeedReIndex in fState then
            fRichMemo.Sections.ReIndex;

        // ������������� ������. ���������� ������� �����, �������
        // ����������, ���� ������� �� ������������, ��������� ������;
        // ���������� ������ ��������������
        if fState * [ssTextChanged, ssNeedReparseAll] <> [] then
            Parse(ssNeedReparseAll in fState, True);

        // �������������� ������, ������� ��� �� ����������������
        // � ������������ ������
        fRichMemo.ReDraw;

        // ��������� ScrollBars
        if not (csDesigning in fRichMemo.ComponentState) then
            fRichMemo.UpdateScrollBars;
    end;
end;


// ����� ���������� ���� ����� (EntireText is True) ��� ������ ������������
// ���� (NeedRepaint is True) - ������������ ����������� ���������� �����
procedure TMPSynMemoStrings.Parse(const EntireText : Boolean; const NeedRepaint: Boolean = False);
var Row: Integer;
    NeedNext: Boolean;
    Sp: TMPSyntaxParser;
begin
    // ������������� ������. ���������� ������� �����, �������
    // ����������, ���� ������� �� ������������, ��������� ������;
    NeedNext := False;
    Row := 0;
    while Row < Count do begin
        Sp := Parser[Row];
        if EntireText or Sp.NeedReparse then begin
            NeedNext := Self.ParseLine(Row, not EntireText);
            if NeedRepaint then
                fRichMemo.NeedRedraw(Row);
        end else
        if NeedNext and (Sp.Count <> 0) then begin
            NeedNext := Self.ParseLine(Row, True);
            if NeedRepaint then
                fRichMemo.NeedRedraw(Row);
        end;
        Inc(Row);
    end;
    fState := fState - [ssTextChanged, ssNeedReparseAll];
end;


// Parse() ������ ����� ������
// !! ���������� ������, ���� ��������� ������ ������� ��������� �����
// (� ������ ������������ ��������� �������������� ����������� � ����� ������ ������ � ������ ���������)
function TMPSynMemoStrings.ParseLine(const Index: Integer; const TestNextLine: Boolean): Boolean;
var i: integer;
    Key: TToken;
begin
    Result := False;
    // ��������� - ��� ������ �������� ��������� ������
    if Index >= Count then Exit;
    Key := tokText;

    // ������������� ���������� �������� ������ � �������,
    // ��� ������� ������ ������ � �������������� �����������
    for i := Index - 1 downto 0 do
        with Parser[i] do
            if Count > 0 then begin
                if LastToken in [tokMLCommentBeg, tokELCommentBeg] then
                    Key := LastToken;
                Break;
            end;

    // ������� ������
    {$IFDEF SYNDEBUG}
    fRichMemo.LogFmt('Strings.Parse %d', [Index]);
    {$ENDIF}
    Key := Parser[Index].Parse(Get(Index), Index, Key, fRichMemo.fParseAttributes);

    // ���� ���������� (TestNextLine = True),
    // �� ������������� �������� ������ ����, ��� ����,
    // ����� ������ - ����� �� ���������� ������, ��� ���.
    if TestNextLine then
        for i := Index + 1 to Count - 1 do
            with Parser[i] do
                if Count > 0 then begin
                    Result := ((Key   = tokMLCommentBeg) and (FirstToken <> Key))
                           or ((Key   = tokELCommentBeg) and (FirstToken <> Key))
                           or ((FirstToken = tokMLCommentBeg) and (Key <> FirstToken))
                           or ((FirstToken = tokELCommentBeg) and (Key <> FirstToken));
                    Break;
                end;

end;


// LoadFromStream() ��������� ����� �� ������
// ����� �������� ����������� � ��������, ������ ������� � ���������� ������ ���������
procedure TMPSynMemoStrings.LoadFromStream(Stream: TStream);
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.LoadFromStream {');
    {} {$ENDIF}

    BeginUpdate;
    { ��������� ������ ��������� ����� }
    fDirectAccess := True;
    try
        inherited LoadFromStream(Stream);
    finally
        fDirectAccess := False;
        // ������ ��������� ������
        fRichMemo.Sections.Scan;
        // ��������� �����������, ��������������, ���������
        fRichMemo.NeedRedrawAll;
        fState := [ssNeedReIndex, ssNeedReparseAll];
        EndUpdate;
    end;

    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('} Strings.LoadFromStream - Ok');
    {} {$ENDIF}
    // ����� ������ ���������
    fRichMemo.Change([ciText, ciSelection, ciSections, ciUndoStack]);
end;


// SaveToStream() ��������� ����� � �����.
// ��������������, ���� ����������, ��������� ������� ������
procedure TMPSynMemoStrings.SaveToStream(Stream: TStream);
var Sl: TStringList;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.SaveToStream');
    {} {$ENDIF}

    // ������� ��������������� �����
    Sl := TStringList.Create;
    // ���� � �������� ���������
    Sl.Assign(self);
    // ���� � ���������� ������� ������ �������� ������,
    // ��������� �������� ��������� ���������� ������
    if smoWriteMarkersOnSave in fRichMemo.Options then
        fRichMemo.Sections.FillOutput(Sl);
    try
        // ����� ��������� ����� � �����
        Sl.SaveToStream(Stream);
    finally
        // �������� ���
        Sl.Free;
    end;
    // ����� ������� - ������ ���������� ���� ���������
    SetModified(False);
    // �������� ���������� � ������
    fRichMemo.Change([ciText]);
end;


// ��������� ����� �� �����, ������������ �������� ����� �����
// � �������� ��������� �����������.
procedure TMPSynMemoStrings.LoadFromFile(const NewFileName: string);
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.LoadFromFile(' + NewFileName + ') {');
    {} {$ENDIF}

    inherited;
    // ����� ���.. =)
    FileName := NewFileName;
    fVirtualFileName := False;
    // ����� ��������������� ����������
    SetModified(False);

    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('} Strings.LoadFromFile - Ok');
    {}{$ENDIF}
end;


// ��������� ���������� � ����� � �������� ������
procedure TMPSynMemoStrings.SaveToFile(const NewFileName: string);
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.SaveToFile(' + NewFileName + ')');
    {} {$ENDIF}

    inherited;
    FileName := NewFileName;
    fVirtualFileName := False;
    SetModified(False);
end;


// New() ������� ����� ��������
procedure TMPSynMemoStrings.New;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.New');
    {} {$ENDIF}
    Clear;
    fRichMemo.Reset;
    FileName := UNTITLEDFN + IntToStr(GlobalUntitledIndex) + '.txt';
    fVirtualFileName := True;
    Inc(GlobalUntitledIndex);
    fState := [];
    fRichMemo.Change([ciText, ciSelection, ciSections, ciUndoStack]);
end;


// IsValidLineIndex() �������� �� �������� ������ ������
function TMPSynMemoStrings.IsValidLineIndex(const Row: Integer): Boolean;
begin
    Result := InRange(Row, 0, Count - 1);
end;


// GetParser() �������������� ���������� ������ ��������� ������
function TMPSynMemoStrings.GetParser(const Row: Integer): TMPSyntaxParser;
begin
    Result := TMPSyntaxParser(Objects[Row]);
end;


// SetFileName() ������������� ��� �����
procedure TMPSynMemoStrings.SetFileName(const Value: string);
var F: TCustomForm;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.SetFileName(' + Value + ')');
    {} {$ENDIF}
    fFileName := Value;
    { ������� ��� ����� � ��������� �������� }
    if (smoShowFileNameInTabSheet in fRichMemo.fOptions)
    and Assigned(fRichMemo.Parent)
    and (fRichMemo.Parent is TTabSheet) then
        TTabSheet(fRichMemo.Parent).Caption := ExtractFileName(fFileName);
    { ������� ��� ����� � ��������� ����� }
    if smoShowFileNameInFormCaption in fRichMemo.fOptions then begin
        F := GetParentForm(fRichMemo);
        if F <> nil then
            F.Caption := Application.Title + '-' + fFileName;
    end;
end;


// SetModified() ���������� ���������� ��������� ������
procedure TMPSynMemoStrings.SetModified(const Value: Boolean);
begin
    if Value <> fModified then begin
        fModified := Value;
        {$IFDEF SYNDEBUG}
        fRichMemo.Log('Strings.SetModified ' + BoolToStr(Value));
        {$ENDIF}
        fRichMemo.Change([ciText]);
    end;
end;



{ TMPSMSectionClone }

// ����������� ������� ������ �� 1
procedure TMPSMSectionClone.AddRef;
begin
    Inc(fRefCount);
end;


// ��������� ������� ������ �� 1.
// ��� ������ ������� ������ ������ 0, ������ ������������
procedure TMPSMSectionClone.Release;
begin
    Dec(fRefCount);
    if fRefCount <= 0 then Free;
end;



// Class TMPSynMemoSection Implementation

// Create() �����������
constructor TMPSynMemoSection.Create;
begin
    inherited Create(True);
end;


// GetSections() ���������� ��������� ������ �� �������
function TMPSynMemoSection.GetSections(const Idx: Integer): TMPSynMemoSection;
begin
    Assert(InRange(Idx, 0, Count - 1), 'Bad nested section index: ' + IntToStr(Idx));
    Result := TMPSynMemoSection(Items[Idx])
end;


// ������������� ����� ������� ����������� ������
// ���������� �������� ������� ���������� ������
procedure TMPSynMemoSection.SetLevel(const Value: Integer);
var i: Integer;
begin
    fLevel := Value;
    for i := 0 to Count - 1 do
        Sections[i].SetLevel(fLevel + 1);
end;



// Class TMPSynMemoManager Implementation

// Create() ����������� ��������� ������
constructor TMPSynMemoSections.Create(Owner: TMPCustomSyntaxMemo);
begin
    inherited Create;
    fRichMemo := Owner;
    fRoot     := TMPSMSectionClone.Create;
    fIndexes  := TList.Create;
    fRoot.AddRef;
    Scan;
end;


// Destroy() ���������� ��������� ������
destructor TMPSynMemoSections.Destroy;
begin
    fIndexes.Free;
    fRoot.Free;
    inherited;
end;


// ���������� ��� ��������� ������
class function TMPSynMemoSections.DetectSectionMark(const s: string): TSectionMark;
begin
    if s = '' then Result := smNone else
    if PDWORD(s)^ = PDWORD(SectionMarks[smExpanded])^ then Result := smExpanded else
    if PDWORD(s)^ = PDWORD(SectionMarks[smCollapsed])^ then Result := smCollapsed else
    if PDWORD(s)^ = PDWORD(SectionMarks[smEnd])^ then Result := smEnd else
        Result := smNone;
end;


// ���������� ��� ��������� ������, �������� ����������� ������
function TMPSynMemoSections.SectionBorder(const Row: Integer): TSectionMark;
begin
    with Section[Row] do
        if Row = RowBeg then
            if Collapsed
                then Result := smCollapsed
                else Result := smExpanded
        else
            if Row = RowEnd
                then Result := smEnd
                else Result := smNone;
end;


// ���������� ��������� ������ ����� �������� ��� ����� ��������� � �����������
function TMPSynMemoSections.Next(Sec: TMPSynMemoSection): TMPSynMemoSection;
    {}
    function _next(Sec: TMPSynMemoSection): TMPSynMemoSection;
    var n: Integer;
    begin
        if Sec = fRoot then
            Result := nil
        else begin
            n := Sec.Parent.IndexOf(Sec);
            if n < Sec.Parent.Count - 1
                then Result := Sec.Parent.Sections[n + 1]
                else Result := _next(Sec.Parent);
        end;
    end;
    {}
begin
    if Sec.Count > 0
        then Result := TMPSynMemoSection(Sec.First)
        else Result := _next(Sec);
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Sections.Next');
    {$ENDIF}
end;


// ���������� ���������� ������ ����� �������� ��� ����� ��������� � �����������
function TMPSynMemoSections.Prev(Sec: TMPSynMemoSection): TMPSynMemoSection;
    function _last(Sec: TMPSynMemoSection): TMPSynMemoSection;
    begin
        Result := Sec;
        if Result.Count > 0 then
            Result := _last(TMPSynMemoSection(Result.Last));
    end;
var n: Integer;
begin
    if Sec = fRoot then
        Result := nil
    else begin
        n := Sec.Parent.IndexOf(Sec);
        if n > 0 then
            Result := _last(Sec.Parent.Sections[n - 1])
        else
        if Sec.Parent = fRoot then
            Result := nil
        else
            Result := Sec.Parent;
    end;
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Sections.Prev');
    {$ENDIF}
end;


// ���������� ������, ������� ����������� ������
function TMPSynMemoSections.GetSection(const Row: Integer): TMPSynMemoSection;
begin
    Result := fRichMemo.Lines.Parser[Row].Section;
end;


// ������������� ������, ������� ����������� ������
procedure TMPSynMemoSections.SetSection(const Row: Integer; Value: TMPSynMemoSection);
begin
    fRichMemo.Lines.Parser[Row].Section := Value;
end;


// ���������� True, ���� ������ ��������� ������ �����
// !!! �������� ������ ����� �������������� ����� !!!
function TMPSynMemoSections.Visible(const Sec: TMPSynMemoSection): Boolean;
begin
    if ssNeedReIndex in fRichMemo.Lines.State then
        ReIndex;
    Result := fRichMemo.Lines.Parser[Sec.RowBeg].VisibleIndex >= 0;
end;


// ������ �������� ������
// ���� Recursive = True, ������ ��� ��������� ������
procedure TMPSynMemoSections.Collapse(const Row: Integer; const Recursive, SafeSelf: Boolean);
var Sec: TMPSynMemoSection;
    { ��� ������ �������� }
    procedure CollapseChildren(Father: TMPSynMemoSection);
    var i: Integer;
    begin
        if Recursive then
            for i := Father.Count - 1 downto 0 do
                CollapseChildren(Father[i]);
        if (Father.Level = 0) or ((Father = Sec) and SafeSelf) then Exit;
        Father.Collapsed := True;
    end;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.Collapse(%d)', [Row]);
    {} {$ENDIF}

    // ������ ������ ���� ������������
    with fRichMemo.Lines do begin
        if ssNeedReindex in State then ReIndex;
        BeginUpdate;
        Sec := Section[Row];
        CollapseChildren(Sec);
        State := State + [ssNeedReIndex];
        fRichMemo.NeedRedrawAll;
        EndUpdate;
    end;
    fRichMemo.Change([ciSections]);
end;


// ���������� �������� ������
// ���� Recursive = True, ���������� ��� ��������� ������
// ���� ParentRecursive = True, ���������� ���� ���������
procedure TMPSynMemoSections.Expand(const Row: Integer; const Recursive, ParentRecursive: Boolean);
    procedure ExpandChildren(Father: TMPSynMemoSection);
    var i: Integer;
    begin
        Father.Collapsed := False;
        if Recursive then
            for i := Father.Count - 1 downto 0 do
                ExpandChildren(Father[i]);
    end;
var Sec: TMPSynMemoSection;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.Expand(%d)', [Row]);
    {} {$ENDIF}

    // ������ ������ ���� ������������
    if ssNeedReindex in fRichMemo.Lines.State then
        ReIndex;
    with fRichMemo.fLines do begin
        BeginUpdate;
        Sec := Self.Section[Row];
        ExpandChildren(Sec);
        if ParentRecursive then
            while Sec.Level > 1 do begin
                Sec := Sec.Parent;
                Sec.Collapsed := False;
            end;
        State := State + [ssNeedReIndex];
        fRichMemo.NeedRedrawAll;
        EndUpdate;
    end;
    fRichMemo.Change([ciSections]);
end;


// ��������� ������.
// ���� Recursive = True, ������� ��� ��������� ������
procedure TMPSynMemoSections.Explode(const Row: Integer; const Recursive: Boolean);
    { Recurse }
    procedure ExplodeChildren(Father: TMPSynMemoSection);
    var i, n: Integer;
        Child: TMPSynMemoSection;
    begin
        if Father.Level > 0 then begin
            n := Father.Parent.IndexOf(Father);
            for i := Father.Count-1 downto 0 do begin
                // ���� ������ ���� ������ ���� ���������,
                // ��� ���� ������ ����������� ��������
                Child := Father[i];
                Child.Level := Child.Level - 1;
                Child.Parent := Father.Parent;
                Father.Parent.Insert(n+1, Father.Extract(Child));
                if Recursive then
                    ExplodeChildren(Child);
            end;
            // ���� ������ ����� ������������ ������������ ������,
            // ������ ��� ����������� �������� ����������� ������
            for i := Father.RowBeg to Father.RowEnd do
                with fRichMemo.Lines.Parser[i] do
                    if Section = Father then
                        Section := Father.Parent;
            // ������� ����������� ������
            Father.Parent.Delete(n);
        end;
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.Explode(%d)', [Row]);
    {} {$ENDIF}

    // ������ ������ ���� ������������
    if ssNeedReindex in fRichMemo.Lines.State then
        ReIndex;
    { TODO : � ���� ����������� - ���-�� ����� �� ���.. }
    MakeUnique;
    with fRichMemo.Lines do begin
        BeginUpdate;
        ExplodeChildren(Section[Row]);
        State := State + [ssSectionsChanged, ssNeedReIndex];
        fRichMemo.NeedRedrawAll;
        SetModified(True);
        EndUpdate;
    end;
    fRichMemo.Change([ciText, ciSelection, ciSections]);
end;


{ ������� ����� ������ � ������� ��������� ������������ }
function TMPSynMemoSections.New(const Row1, Row2: Integer; const IsCollapsed: Boolean = False): TMPSynMemoSection;
var i: Integer;
    Father, iSec: TMPSynMemoSection;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.New(%d, %d)', [Row1, Row2]);
    {} {$ENDIF}

    // ������ ������ ���� ������������
    if ssNeedReindex in fRichMemo.Lines.State then
        ReIndex;
    { TODO : � ���� ����������� - ���-�� ����� �� ���.. }
    MakeUnique;

    // ���� ���� ������ ����������� ������ "A", � ������ ������
    // ����������� � �������� ("^A"), �� ��� ���� �� �������� � ��������,
    // �� ������� ��������� ������������ ������ ("A"->(^A"),
    // �, �����, ������� � ������ - ���� � ����� ��������,
    // ���� � ����� ���������������
    if ((Section[Row2] = Section[Row1].Parent) and (SectionBorder(Row2) = smNone))
    or ((Section[Row1] = Section[Row2].Parent) and (SectionBorder(Row1) = smNone)) then
        Explode(Row1, False);

    // ���� ����� ����� ����� �������� ��������� �������� �������������,
    // ����������� ���������� nil � ������� �� ���������
    if (Section[Row1] <> Section[Row2])
    or (SectionBorder(Row1) <> smNone)
    or (SectionBorder(Row2) <> smNone) then begin
        Result := nil;
        Exit;
    end;

    // �������� ���������
    fRichMemo.Lines.BeginUpdate;

    // ������� ���� ����� ������
    Father := Section[Row1];

    // ������� ����� ������
    Result := TMPSynMemoSection.Create;
    Result.Parent    := Father;
    Result.RowBeg    := Row1;
    Result.RowEnd    := Row2;
    Result.Level     := Father.Level + 1;
    Result.Collapsed := IsCollapsed;

    // ��������� ������ � ����� ������
    for i := Row1 to Row2 do begin
        iSec := Section[i];
        // ���� ������ ����� ������������ ������������ ������,
        // ������ ��� ����������� ��������� �������� ������
        // ( ��� ����� ������ ;)
        if iSec = Father then
            Section[i] := Result
        else
        // ���� ������ ����������� ������ ���� ��������� ������,
        // ��� ���� ������ ����������� ������� � ����� �������
        // ������� ���������� ;))
        if (i = iSec.RowBeg) and (iSec.Parent = Father) then begin
            iSec.Level := Result.Level + 1;
            iSec.Parent := Result;
            Result.Add(Father.Extract(iSec));
        end;
    end;

    // ��������� ����� ������ � �������� ������
    i := Father.Count;
    while (i > 0) and (Father[i-1].RowBeg > Row1) do
        Dec(i);
    Father.Insert(i, Result);

    // ��������� ���������
    with fRichMemo.Lines do begin
        State := State + [ssSectionsChanged, ssNeedReIndex];
        fRichMemo.NeedRedrawAll;
        SetModified(True);
        EndUpdate;
    end;

    // �����������
    fRichMemo.Change([ciText, ciSelection, ciSections]);
end;


// ������� ������ - ��������������� ������� ������
// !!! ������ ��� �������� � �������� ��������� !!!
procedure TMPSynMemoSections.DeleteRow(const Row: Integer);
    { Recurse }
    procedure UpdateIndexes(Sec: TMPSynMemoSection);
    var i: Integer;
    begin
        if Sec.RowBeg > Row then Dec(Sec.fRowBeg);
        if Sec.RowEnd > Row then begin
            Dec(Sec.fRowEnd);
            { ���������� ��������������� ������� ��������� ������}
            for i := 0 to Sec.Count - 1 do
                UpdateIndexes( Sec.Sections[i] );
        end;
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.DeleteRow(%d)', [Row]);
    {} {$ENDIF}

    { TODO : � ���� ����������� - ���-�� ����� �� ���.. }
    MakeUnique;

    // ���� ��������� ������ �������� �������� ������, ������ �����������.
    with fRichMemo do
        if Sections.SectionBorder(Row) <> smNone then
            Explode(Row, False);

    // .. � ��� ����� �������������� �������
    UpdateIndexes(fRoot);
    with fRichMemo.Lines do
        State := State + [ssSectionsChanged, ssNeedReIndex];
end;


// ����������� ������ - ��������������� ������� ������
// !!! ������ ��� �������� � �������� ��������� !!!
procedure TMPSynMemoSections.InsertRow(const Row: Integer);
var ParentSec: TMPSynMemoSection;
    {}
    procedure UpdateIndexes(Sec: TMPSynMemoSection);
    var i: Integer;
    begin
        if Row <= Sec.RowBeg then
            Inc(Sec.fRowBeg);
        if Row <= Sec.RowEnd then begin
            Inc(Sec.fRowEnd);
            { ���������, �� � ��� �� ������ ��������� ������ }
            if InRange(Row, Sec.RowBeg, Sec.RowEnd) and (Sec.Level > ParentSec.Level) then
                ParentSec := Sec;
            { ���������� ��������������� ������� ��������� ������}
            for i := 0 to Sec.Count - 1 do
                UpdateIndexes( Sec.Sections[i] );
        end;
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.InsertRow(%d)', [Row]);
    {} {$ENDIF}

    { TODO : � ���� ����������� - ���-�� ����� �� ���.. }
    MakeUnique;
    ParentSec := fRoot;
    UpdateIndexes(fRoot);
    Section[Row] := ParentSec;
    with fRichMemo.Lines do
        State := State + [ssSectionsChanged, ssNeedReIndex];
end;


// FillOutput() ��������� �������� ����� � ����������� �� ����� ��������� �������
procedure TMPSynMemoSections.FillOutput(const Sl: TStringList);
const pm: array[Boolean] of string[4] = ('{<+}', '{<-}');
    {}
    procedure MarkSection(Sec: TMPSynMemoSection);
    var i: Integer;
    begin
        if Sec <> fRoot then begin
            Sl[Sec.RowBeg] := pm[Sec.Collapsed] + Sl[Sec.RowBeg];
            Sl[Sec.RowEnd] := '{>>}' + Sl[Sec.RowEnd];
        end;
        for i := 0 to Sec.Count - 1 do
            MarkSection(Sec.Sections[i]);
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Sections.FillOutput');
    {} {$ENDIF}
    MarkSection(fRoot);
end;


{ TODO : ��� � ��� � ����� ����������� - ������ � ���� }
// ������� ������ ������ ���������� ����������
procedure TMPSynMemoSections.MakeUnique;
    { ������� ����� ������ - recurse }
    function Clone(const Father, Sec: TMPSynMemoSection): TMPSynMemoSection;
    var i: Integer;
    begin
        Result := TMPSynMemoSection.Create;
        Result.fParent    := Father;
        Result.fRowBeg    := Sec.fRowBeg;
        Result.fRowEnd    := Sec.fRowEnd;
        Result.fLevel     := Sec.fLevel;
        Result.fCollapsed := Sec.fCollapsed;
        for i := 0 to Sec.Count - 1 do
            Result.Add( Clone(Result, Sec.Sections[i]) );
    end;
    {}
var NewRoot: TMPSMSectionClone;
    i: Integer;
begin
    if ssUndoProcess in fRichMemo.Lines.State then Exit;
    if fRoot.fRefCount > 1 then begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Sections.MakeUnique %d->%d', [fRoot.fRefCount, fRoot.fRefCount + 1]);
        {} {$ENDIF}

        { ������� �������� /���������� ��������� ������/ ���� ������ ������ }
        NewRoot := TMPSMSectionClone.Create;
        NewRoot.fParent    := nil;
        NewRoot.fRowBeg    := fRoot.fRowBeg;
        NewRoot.fRowEnd    := fRoot.fRowEnd;
        NewRoot.fLevel     := 0;
        NewRoot.fCollapsed := False;
        for i := 0 to fRoot.Count - 1 do
            NewRoot.Add( Clone(NewRoot, fRoot.Sections[i]) );
        SetRoot(NewRoot);
    end else begin

        { ������� ����������� /���������� ��������� ������/ ���� ������ ������ }
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('Sections.MakeUnique VIRTUAL');
        {} {$ENDIF}
    end;
end;


// ���������� ������ ������ ��� ������������� �����
function TMPSynMemoSections.AsText: string;
var sl: TStringList;
    procedure SecAsString(Sec: TMPSynMemoSection);
    var i: Integer;
    begin
        sl.Append(Format('%s%d..%d %s',
           [StringOfChar(' ', Sec.Level * 4),
            Sec.RowBeg,
            Sec.RowEnd,
            ifthen(Sec.Collapsed, 'Collapsed')]));
        for i := 0 to Sec.Count - 1 do
            SecAsString(Sec.Sections[i]);
    end;
begin
    sl := TStringList.Create;
    sl.Append('Sections');
    SecAsString(fRoot);
    sl.Append('End of sections');
    Result := sl.Text;
    sl.Free;
end;


// ������ ��������������� ������ ������������ ������
procedure TMPSynMemoSections.ReIndex;
var Row: Integer;
    {}
    procedure ProcessSection(const Sec: TMPSynMemoSection; ParentOpen: Boolean);
    var ChildIndex: Integer;
    begin
        ChildIndex := 0;
        if Sec.Level > fMaxLevel then fMaxLevel := Sec.fLevel;
        if ParentOpen and (Sec.fLevel > fMaxExpandLevel)
            then fMaxExpandLevel := Sec.fLevel;
        while Row <= Sec.fRowEnd do begin
            if (ChildIndex >= Sec.Count)
            or (Row < Sec.Sections[ChildIndex].RowBeg)
            or (Row > Sec.Sections[ChildIndex].RowEnd) then begin
                with fRichMemo.Lines.Parser[Row] do begin
                    Section := Sec;
                    if ParentOpen and (not Sec.Collapsed or (Row = Sec.RowBeg))
                        then fVisibleIndex := fIndexes.Add(Pointer(Row))
                        else fVisibleIndex := -1;
                end;
                Inc(Row);
            end else begin
                ProcessSection(Sec.Sections[ChildIndex], ParentOpen and not Sec.Collapsed);
                Inc(ChildIndex);
            end;
        end;
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Sections.ReIndex');
    {} {$ENDIF}
    Dec(fRoot.fRowEnd);
    fMaxLevel       := 0;
    fMaxExpandLevel := 0;
    Row             := 0;
    fIndexes.Clear;
    ProcessSection(fRoot, True);
    Inc(fRoot.fRowEnd);
    { ��������� ���������� }
    fRichMemo.Lines.State := fRichMemo.Lines.State - [ssNeedReIndex];
    { �������� ��������� ��������� }
    fRichMemo.Change([ciSections]);
end;


// ������ ����� ������ ������ (�� ����� ��� �������� � Undo)
procedure TMPSynMemoSections.SetRoot(const Value: TMPSMSectionClone);
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Sections.SetRoot');
    {$ENDIF}
    { ���� ������ �� ��������, ������ ��������������� ������ }
    if fRoot <> Value then begin
        fRoot.Release;
        fRoot := Value;
        fRoot.AddRef;
    end;
    { ��������� ������ }
    ReIndex;
end;


// ����������� ���� ����� � ������� ����� ������
procedure TMPSynMemoSections.Scan;
var Row, i: Integer;
    ParentSec, Sec: TMPSynMemoSection;
    Stack: TObjectStack;
    Sm: TSectionMark;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Sections.SCAN');
    {$ENDIF}
    { ������� ������ ������ }
    with fRoot do begin
        Clear;
        fRowBeg     := -1;
        fRowEnd     := fRichMemo.fLines.Count;
        fLevel      := 0;
        fParent     := nil;
        fCollapsed  := False;
    end;

    { ������� ���� �������� ������ }
    Stack := TObjectStack.Create;

    { ������������� ���� ����� � ������� ����� ������ ������ }
    Row := 0;
    ParentSec := fRoot;
    repeat
        while Row < fRichMemo.Lines.Count do begin
            Sm := TMPSynMemoSections.DetectSectionMark(fRichMemo.Lines[Row]);
            case Sm of
            smExpanded,
            smCollapsed:
                begin
                    { ������� ����� ������ }
                    Sec := TMPSynMemoSection.Create;
                    with Sec do begin
                        fRowBeg     := Row;
                        fRowEnd     := -1;
                        fLevel      := ParentSec.fLevel + 1;
                        fParent     := ParentSec;
                        fCollapsed  := Sm = smCollapsed;
                    end;
                    { ���������� �� ������ ParentSec }
                    ParentSec.Add(Sec);
                    { ������ �� � ���� }
                    Stack.Push(Sec);
                    { ������ �� ������������ }
                    ParentSec := Sec;
                    { ������ ������ �� ��������� ��������� ����� ������������ ���� ������ }
                    fRichMemo.Sections.Section[Row] := ParentSec;
                    { ������� ������ ������ ������ }
                    fRichMemo.Lines[Row] := StuffString(fRichMemo.Lines[Row], 1, SECTION_HEADER_LENGTH, '');
                end;
            smEnd:
                begin
                    { ��������� ���� }
                    if Stack.Count = 0 then begin
                        // ������: ��������������� �������� ������ (������ {>>}):
                        // �������������� - ��������� ������ � ��������� ������
                        fRichMemo.fLines.Insert(Row, SectionMarks[smExpanded]);
                        Continue;
                    end;
                    { ������� ��������� �������� ������ �� ����� � ��������� �� }
                    Sec := TMPSynMemoSection(Stack.Pop);
                    Sec.fRowEnd := Row;
                    { ������ ������ �� ��������� ��������� ����� ������������ ���� ������ }
                    fRichMemo.Sections.Section[Row] := Sec;
                    { ������������ ������� ���������� �� �������� }
                    ParentSec := Sec.fParent;
                    { ������� ������ ����� ������ }
                    fRichMemo.Lines[Row] := StuffString(fRichMemo.Lines[Row], 1, SECTION_HEADER_LENGTH, '');
                end;
            else
                { ������ ������ �� ��������� ��������� ����� ������������ ������� ������ }
                fRichMemo.Sections.Section[Row] := ParentSec;
            end;
            Inc(Row);
        end;

        { ��������� ���� �� ������� �������� ������ }
        if Stack.Count > 0 then
            // ������: �� ������� ���������� {>>}:
            // �������������� - ��������� ������ � ������������
            for i := 0 to Stack.Count - 1 do
                fRichMemo.Lines.Append(SectionMarks[smEnd]);
    until Stack.Count = 0;

    { ����������� ���� }
    Stack.Free;
end;


{ TMPSynMemoUndoItem }

// ����������.
destructor TMPSynMemoUndoItem.Destroy;
begin
    // ������� ����������� ������ ������
    uiSections.Release;
    inherited;
end;



// Class TMPSynMemoRange Implementation

// Create() �����������
constructor TMPSynMemoRange.Create(Owner: TMPCustomSyntaxMemo);
begin
    inherited Create;
    fRichMemo     := Owner;
    fSealing      := True;
    fMaxUndoDepth := 100;
    fUndoStack := TObjectList.Create(True);
    fUndoStack.Capacity := 100;
end;


// Destroy() ����������
destructor TMPSynMemoRange.Destroy;
begin
    fUndoStack.Free;
    inherited;
end;


// Collaps() ����������� ��������� � ������
procedure TMPSynMemoRange.Collapse;
var yb, ye: Integer;
    e: Boolean;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Range.Collapse');
    {} {$ENDIF}

    // ��������� �������� ��������� � �������� ����� ��������� ..
    yb       := fStart.Y;
    ye       := fEnd.Y;
    // .. � �������� ������� ���������
    e        := IsEmpty();
    // �������� ���������
    // ��� ����, ������� ��������� ������ ����� ��������������� ������� �����
    fSealing := True;
    fStart   := fPos;
    fEnd     := fPos;
    // ��������� ����� �������� - �������������� �� ������,
    // ��� ������ ���� ������� ���������
    if not e then
        with fRichMemo do begin
            Lines.BeginUpdate;
            repeat
                NeedRedraw(yb);
                Inc(yb);
            until yb > ye;
            Lines.EndUpdate;
        end;
    // ������������� ���������
    fRichMemo.Change([ciSelection]);
end;


// Enlarge() ����������� ������� ��������� �� Value �������� (��� ����� - ���� EnlargeLine is True)
procedure TMPSynMemoRange.Enlarge(const Value: Integer; const EnlargeLine: Boolean = False; const VisiblesOnly: Boolean = False);
var n, PrevY: Integer;
begin
    fRichMemo.Lines.BeginUpdate;
    fSealing := False;
    if not EnlargeLine then begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Range.Enlarge(Cols=%d)', [Value]);
        {} {$ENDIF}
        // ����������� �����������/��������� ��������� �� �����������
        n := PosX + Value;
        // ������������ ��������� � �������� ������� ������ (��� � Delphi)
        if n < 0 then n := -PosX else
            if n > Length(fRichMemo.Lines[PosY]) then n := Length(fRichMemo.Lines[PosY]) - PosX else
                n := Value;
        // ���� � ���������� �����������, ������ �� �������� - ������ �������
        if n <> 0 then begin
            // ������������ ������� ���������
            if (PosX = StartX) and (PosY = StartY) then Inc(fStart.X, n) else Inc(fEnd.X, n);
            if (StartY = EndY) and (StartX > EndX) then Swap(fStart.X, fEnd.X);
            // ���������� ������ �� �����������, ��� ������������� ����������� ���������
            PosX := PosX + n;
            // �������������� ������� ������
            fRichMemo.NeedRedraw(PosY);
        end
    end else begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Range.Enlarge(Rows=%d)', [Value]);
        {} {$ENDIF}
        // ����������� �����������/��������� ��������� �� ���������
        if VisiblesOnly
            then n := fRichMemo.FindVisibleRow(PosY, Value, True)
            else n := EnsureRange(PosY + Value, 0, fRichMemo.Lines.Count - 1);

        // ���� � ���������� �����������, ������ �� �������� - ������ �������
        if n <> PosY then begin
            // ���������� ��������� ������
            PrevY := PosY;

            // ������������ ������� ���������
            if PointsEqual(fPos, fStart)
                then fStart.Y := n
                else fEnd.Y := n;
            if StartY > EndY then begin
                Swap(fStart.Y, fEnd.Y);
                Swap(fStart.X, fEnd.X);
            end;

            // ���������� ������ �� ���������, ��� ������������� ����������� ���������
            PosY := n;

            // �������������� ������ � ��������� �� ��������
            for n := Min(PrevY, PosY) to Max(PrevY, PosY) do
                fRichMemo.NeedRedraw(n);
        end;
    end;
    fRichMemo.Lines.EndUpdate;
    fRichMemo.Change([ciSelection]);
end;


// ������� ������, ������ ������ ��� ���������� ������� ���������
procedure TMPSynMemoRange.Delete;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Range.Delete');
    {} {$ENDIF}
    if not IsEmpty then
        SetText('')
    else
    if PosX < Length(fRichMemo.fLines[PosY]) then begin
        // ��������� ���; ������ �� � ����� ������ - �������� �������
        EndX := StartX + 1;
        SetText('');
    end else
    if PosY < fRichMemo.fLines.Count - 1 then begin
        // ������ � ����� ������ - ����������� ���� �����
        EndX := 0;
        EndY := StartY + 1;
        SetText('');
    end;
end;


// ����������� ������, � ������ ������� ��������� ������� �����
procedure TMPSynMemoRange.CollapseSection(const Recursive: Boolean);
begin
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} Log('Range.CollapseSection');
        {} {$ENDIF}
        // ���� ������ ������ ������, ������� ��� � ��������� ������
        if Sections.SectionBorder(PosY) in [smNone, smEnd] then
            SetPos( Point(0, Sections.Section[PosY].RowBeg) );
        Sections.Collapse(PosY, Recursive, Recursive);
    end;
end;


// ���������� ������, � ��������� ������� ��������� ������� �����
procedure TMPSynMemoRange.ExpandSection(const Recursive: Boolean);
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.ExpandSection');
    {$ENDIF}
    fRichMemo.Sections.Expand(PosY, Recursive, False);
end;


// ��������� ������
procedure TMPSynMemoRange.ExplodeSection(const Recursive: Boolean);
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.ExplodeSection');
    {$ENDIF}
    Collapse;
    AddUndo;
    fRichMemo.Sections.Explode(PosY, Recursive);
end;


// CreateSection() ������� ������ �� ������ Row1 �� ������ Row2
// ���� Row2 = -1 (�� ���������), ��������� ����� ������ Row1..Row1+1
procedure TMPSynMemoRange.CreateSection;
begin
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} Log('Range.CreateSection');
        {} {$ENDIF}
        Lines.BeginUpdate;
        // Row1 = Row2
        // ��������� ������ ��� ������������� �� ����� ������ ������
        // ������ ����� ���������� � ����� ����� ������
        // ������ �� ����� ���� �������� ������������ ������
        // �������������� ����������� ������ ������
        if (StartY = EndY)
        and (Sections.SectionBorder(StartY) = smNone) then begin
            Collapse;
            // ������� ����� � ���� ������� �������� ������..
            with AddUndo() do begin
                uiSelStart := Point(0, StartY + 1);
                uiSelEnd   := Point(0, StartY + 2);
                uiSealing  := False;
            end;
            // .. ������� �� ��� �������
            Lines.Insert(StartY + 1, '');
            // ������� ������
            Sections.New(StartY, StartY + 1);
        end else
        // Row1 < Row2
        // ��������� �� ������, ��������� � �������� ������ �����������
        // ����� ��� ������ ������� � �� �������� ��������� ���� ������
        if (StartY <> EndY)
        and (Sections.SectionBorder(StartY) = smNone)
        and (Sections.SectionBorder(EndY) = smNone) then begin
            with AddUndo() do begin
                uiSelStart := fPos;
                uiSelEnd   := fPos;
                uiSealing  := True;
            end;
            Sections.New(fStart.Y, fEnd.Y);
            Collapse;
        end;
        SetPos(Point(0, fStart.Y));
        Lines.EndUpdate;
    end;
end;


// ������� � ��������� (Delta=+1) ��� ���������� (Delta=-1) ������,
// ���� ��� ��������, �������
procedure TMPSynMemoRange.GotoSection(const GoForward: Boolean);
var Sec: TMPSynMemoSection;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Range.GotoSection(%s)', [BoolToStr(GoForward)]);
    {} {$ENDIF}
    // �������� ������� ������ (� ������� ��������� ������ � ��������)
    Sec := fRichMemo.Sections.Section[PosY];
    // �������� ����� ���������� ��� ��������� ������
    repeat
        if GoForward
            then Sec := fRichMemo.Sections.Next(Sec)
            else Sec := fRichMemo.Sections.Prev(Sec);
    until (Sec = nil) or fRichMemo.Sections.Visible(Sec);
    // ���� ������ �������, ������������� ������ � � ���������
    if Sec <> nil then
        SetPos( Point(0, Sec.RowBeg) );
end;


// �������� � ����� ������ ����� � ���������� � ��������� �������
procedure TMPSynMemoRange.CopyToClipboard;
var Data: THandle;
    DataPtr: Pointer;
    s: string;
begin
    if IsEmpty then Exit;
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.CopyToClipboard');
    {$ENDIF}
    // ������ �������� �����
    Clipboard.AsText := self.GetText;
    // ���� �� ���������, � ������� ��������� ��������� � ������ �������,
    // ��������� ���������� � �������� ��������� ������
    if not (smoSkipSectionsOnCopy in fRichMemo.Options)
    and (fStart.Y <> fEnd.Y) then begin
        s := GetMarkedText;
        // ��������� ����� ������
        OpenClipboard(Application.Handle);
        try
            // ����������� ���������� �������
            Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, Length(s) + 1);
            try
                // �������� ��������� �� ��
                DataPtr := GlobalLock(Data);
                try
                    Move(PChar(s)^, DataPtr^, Length(s) + 1);
                    SetClipboardData(CF_SYNTAX, Data);
                finally
                    GlobalUnlock(Data);
                end;
            except
                GlobalFree(Data);
                raise;
            end;
        finally
            // ��������� ����� ������
            CloseClipboard;
        end;
    end;
end;


// ��������� � ����� ������ �, ���� ���� ����������, ������ ������
procedure TMPSynMemoRange.PasteFromClipboard;
var Data: THandle;
begin
    if smoReadOnly in fRichMemo.fOptions then Exit;
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.PasteFromClipboard');
    {$ENDIF}
    // ���������� ������� ������� ��� ��������� ������
    fRichMemo.Lines.BeginUpdate;
    if not (smoSkipSectionsOnPaste in fRichMemo.Options) and Clipboard.HasFormat(CF_SYNTAX) then begin
        // ��������� ����� ������
        OpenClipboard(Application.Handle);
        Data := GetClipboardData(CF_SYNTAX);
        try
            // �� ������ ���������� ���������� � �������� ������ � ���������� ������,
            // ������� �� �� ����� �����
            SetMarkedText(PChar(GlobalLock(Data)));
        finally
            GlobalUnlock(Data);
            CloseClipboard;
        end;
    end else
    // ���� ��� ���������� ��� �� ��������, ��������� ������ �����
    if Clipboard.HasFormat(CF_TEXT) then
        SetText( Clipboard.AsText );
    fRichMemo.Lines.EndUpdate;
end;


// CutToClipboard() �������� ����� ��������� � �������� � ����� ������
procedure TMPSynMemoRange.CutToClipBoard;
begin
    if not IsEmpty and not (smoReadOnly in fRichMemo.fOptions) then begin
        {$IFDEF SYNDEBUG}
        fRichMemo.Log('Range.CutToClipboard');
        {$ENDIF}
        CopyToClipboard;
        self.Text := '';
    end;
end;


// IsEmpty() ���������� True, ���� ������� ������ (������ ������� �����)
function TMPSynMemoRange.IsEmpty: Boolean;
begin
    Result := (StartX = EndX) and (StartY = EndY);
end;


// ������������ ����� �����
procedure TMPSynMemoRange.SetPos(const NewPos: TPoint);
begin
    if PointsEqual(fPos, NewPos) then Exit;
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} LogFmt('Range Col = %d Row = %d', [NewPos.X, NewPos.Y]);
        {} {$ENDIF}

        Lines.BeginUpdate;
        // �� ���������
        // ������� ������ ������� ������ ����� ��������� �������������� ������
        // (: ���� ������ ��� ���������� :)
        if NewPos.Y <> fPos.Y then
             CutFinalSpaces(fPos.Y);
        // ������������� ������
        fPos.Y := EnsureRange(NewPos.Y, 0, Lines.Count);
        // ���� ������ ����� ��������� ������ ������ � ��� ��������� ������ ������ �� ������,
        // ��������� ����� ������ - �������-�� � ���� � ������� ���� �������� �����������������
        // ������ ������ ..:)
        if fPos.Y = Lines.Count then
            if (Lines.Count = 0)
            or ((Lines.Count > 0) and (Lines[Lines.Count-1] <> '')) then begin
                Lines.Add('');
                SetPos(Point(0, Lines.Count-1));
            end;
        // �� �����������
        fPos.X := Max(0, NewPos.X);
        // ���� �������� ���������, ������������ ��������� �� �������� ��������� �������
        if fSealing then begin
            fStart := fPos;
            fEnd   := fPos;
        end;
        // ������ ������ ���� ����� �� ������
        MakeVisible(fPos.X, fPos.Y);
        Lines.EndUpdate;
        Change([ciSelection]);
    end;
end;


// ������������� ���� �� �������� ���������
procedure TMPSynMemoRange.SetRange(const Index, Value: Integer);
begin
    case Index of
    0:  SetPos( Point(Value, fPos.Y) );
    1:  SetPos( Point(fPos.X, Value) );
    end;
end;


// ������� ��������� ������� � ������
procedure TMPSynMemoRange.CutFinalSpaces(const Row: Integer);
var s: string;
    Da: Boolean;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Range.CutFinalSpaces(%d)', [Row]);
    {} {$ENDIF}
    with fRichMemo.Lines do
        if IsValidLineIndex(fPos.Y) then begin
            s := TrimRight(Strings[fPos.Y]);
            if Length(s) <> Length(Strings[fPos.Y]) then begin
                Da := fDirectAccess;
                fDirectAccess := True;
                Strings[fPos.Y] := s;
                fDirectAccess := Da;
            end;
        end;
end;


// GetText() ���������� ����� ���������
function TMPSynMemoRange.GetText: string;
var Row: Integer;
begin
    if IsEmpty then
        Result := ''
    else
    if fStart.Y = fEnd.Y then
        Result := Copy(fRichMemo.Lines[fStart.Y], fStart.X + 1, fEnd.X - fStart.X)
    else begin
        Result := Copy(fRichMemo.Lines[fStart.Y], fStart.X + 1, MAXINT);
        for Row := StartY + 1 to EndY - 1 do
            Result := Result + #13#10 + fRichMemo.Lines[Row];
        Result := Result + #13#10 + LeftStr(fRichMemo.Lines[fEnd.Y], fEnd.X);
    end;
end;


// ���������� ����� ��������� � ��������� ����� ������
function TMPSynMemoRange.GetMarkedText: string;
var Row, Row1, Row2: Integer;
begin
    with fRichMemo do begin
        // ������ ����� ������������� ������ ��� ������ �����
        Row1 := fStart.Y;
        if fStart.X > 0 then Inc(Row1);
        Row2 := fEnd.Y;
        if fEnd.X < Length(Lines[fEnd.Y]) then Dec(Row2);
        // ���� ������ ������ ���� �� ������, � �������� ��� ����� ������
        if Row1 > fStart.Y
            then Result := Copy(Lines[fStart.Y], fStart.X, MAXINT) + #13#10
            else Result := '';
        // ������ ������ �������� � ������ ������
        for Row := Row1 to Row2 do
            with Sections.Section[Row] do
                if (Row = RowBeg) and (RowEnd <= Row2) then
                    if Collapsed
                        then Result := Result + SectionMarks[smCollapsed] + Lines[Row] + #13#10
                        else Result := Result + SectionMarks[smExpanded] + Lines[Row] + #13#10
                else
                if (Row = RowEnd) and (RowBeg >= Row1) then
                    Result := Result + SectionMarks[smEnd] + Lines[Row] + #13#10
                else
                    Result := Result + Lines[Row] + #13#10;
        // ���� ��������� ������ ���� �� ������, � �������� ��� ����� ������
        if Row2 < fEnd.Y then
            Result := Result + LeftStr(Lines[fEnd.Y], fEnd.X)
        else
            System.SetLength(Result, Length(Result) - 2);
    end;
end;


// DoUndo() ���������� ����� (���� ���� ����)
procedure TMPSynMemoRange.DoUndo;
begin
    if CanUndo then
        with fRichMemo, TMPSynMemoUndoItem(fUndoStack.Last) do begin
            {} {$IFDEF SYNDEBUG}
            {} Log('Range.DoUndo');
            {} {$ENDIF}

            Lines.BeginUpdate;

            // ������ ���������
            fStart :=   uiSelStart;
            fEnd :=     uiSelEnd;
            fSealing := uiSealing;

            // ��������������� ������� �����
            Lines.State := Lines.State + [ssUndoProcess];
            Self.SetText(uiText);
            Lines.State := Lines.State - [ssUndoProcess];

            // ������� ������ ������
            Sections.EntireSection := uiSections;

            // ������ ������� �������
            SetPos( uiCaretPos );

            // ������� �������������� �����
            with fUndoStack do Delete(Count - 1);

            // ��������� ���������
            Change([ciUndoStack]);
            Lines.State := [ssNeedReIndex, ssNeedReparseAll];
            fRichMemo.NeedRedrawAll;
            Lines.EndUpdate;
        end;
end;


// ������� ����� ������
function TMPSynMemoRange.AddUndo(const UndoText: string = ''): TMPSynMemoUndoItem;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.LogFmt('Range.AddUndo("%.20s")', [UndoText]);
    {$ENDIF}
    Result := TMPSynMemoUndoItem.Create;
    Result.uiCaretPos := fPos;
    Result.uiSelStart := fStart;
    Result.uiSelEnd   := fEnd;
    Result.uiSealing  := fSealing;
    Result.uiSections := fRichMemo.Sections.EntireSection;
    Result.uiText     := UndoText;
    Result.uiSections.AddRef;
    { ���������� ����� }
    if fUndoStack.Count >= fMaxUndoDepth then
        fUndoStack.Delete(0);
    fUndoStack.Add(Result);
    fRichMemo.Change([ciUndoStack]);
end;


// ������ ���� ������
procedure TMPSynMemoRange.ClearUndo;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.ClearUndo');
    {$ENDIF}
    fUndoStack.Clear;
    Assert(fRichMemo.Sections.EntireSection.RefCount = 1,
        '����� ClearUndo ������ ���� fRichMemo.Sections.EntireSection.RefCount == 1');
    fRichMemo.Change([ciUndoStack]);
end;


{ TODO : ��� ����� ������ �� Sections.Scan ! }
// ��������� ����� � ��������� ������
procedure TMPSynMemoRange.SetMarkedText(Value: string);
type TIntArray = array of Integer;

    { ���������� ������ ������ �� ����������� ������ � �������� ����������� }
    procedure _Scan(var s: string; var secs: TIntArray);
    const signs: array [Boolean] of Integer = (-1, +1);
    var Sl: TStringList;
        i: Integer;
        Stack: TStack;
        Sm: TSectionMark;
    begin
        Sl := TStringList.Create;
        Sl.Text := s;
        secs := nil;
        Stack := TStack.Create;
        for i := 0 to Sl.Count - 1 do begin
            Sm := TMPSynMemoSections.DetectSectionMark(Sl[i]);
            case Sm of
            smExpanded,
            smCollapsed:
                begin
                    Stack.Push(Pointer((i + 1) * signs[Sm = smExpanded]));
                    Sl[i] := Copy(Sl[i], SECTION_HEADER_LENGTH + 1, MAXINT);
                end;
            smEnd:
                begin
                    if Stack.AtLeast(1) then begin
                        System.SetLength(secs, Length(secs) + 2);
                        secs[High(secs)-1] := Integer(Stack.Pop);
                        secs[High(secs)]   := i;
                    end;
                    Sl[i] := Copy(Sl[i], SECTION_HEADER_LENGTH + 1, MAXINT);
                end;
            end;
        end;
        Stack.Free;
        s := Sl.Text;
        Sl.Free;
    end;
    {}

var i, Row1, Row2: Integer;
    SafeStart: TPoint;
    SecIndexes: TIntArray;
begin
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} LogFmt('Range.SetMarkedText("%.20s")', [Value]);
        {} {$ENDIF}

        Lines.BeginUpdate;

        // ���������� ��������� ������� �������
        SafeStart := fStart;

        // ���� ������ ���������, ���� ���������, ���� �� ��������� �� ������
        // ��������� ����� ������ ������ � ���� ������, ����� �� ���������� ���-�� ���� Line10: abc{<+}def
        if (SafeStart.X > 0)
        and (TMPSynMemoSections.DetectSectionMark(Value) <> smNone) then
            System.Delete(Value, 1, SECTION_HEADER_LENGTH);

        // ������ � ��������� ������
        _Scan(Value, SecIndexes);

        // ��������� ��� ����� � �����������������
        SetText(Value);
        Sections.ReIndex;

        // ������� ������� ������ ���, ��� ��� ����������
        for i := 0 to Length(SecIndexes) shr 1 - 1 do begin
            Row1 := SafeStart.Y + SecIndexes[i*2] * sign(SecIndexes[i*2]) - 1;
            Row2 := SafeStart.Y + SecIndexes[i*2 + 1];
            Sections.New(Row1, Row2, SecIndexes[i*2] < 0);
        end;

        // ����������� ��������� ������ ������ ������
        SecIndexes := nil;

        // �������������� �����
        Lines.EndUpdate;
    end;
end;


// SetText() ����� �������. ������ ����� ���������.
procedure TMPSynMemoRange.SetText(const Value: string);
var Sl: TStringList;
    n, n1, n2: Integer;
    NewSelEnd: TPoint;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Range.SetText("%.20s")', [Value]);
    {} {$ENDIF}

    // ������������ ������� �����
    with fRichMemo do
        if IsEmpty and (PosX > Length(Lines[PosY])) then
            Lines[PosY] := Lines[PosY] + StringOfChar(' ', PosX - Length(Lines[PosY]));

    Sl := TStringList.Create;
    Sl.Text := Value + #13#10;
    with fRichMemo do begin
        { ������� ��������������� ������ }
        n1 := EndY - StartY + 1;
        n2 := Sl.Count;

        // ������� ��������������� ������
        NewSelEnd.Y := fStart.Y + n2 - 1;
        Sl[0] := LeftStr(fLines[fStart.Y], fStart.X) + Sl[0];
        NewSelEnd.X := Length(Sl[n2-1]);
        Sl[n2-1] := Sl[n2-1] + RightStr(fLines[fEnd.Y], Length(fLines[fEnd.Y]) - fEnd.X);

        { ��������� ��������� ������ }
        if not (ssUndoProcess in Lines.State) then
            with AddUndo do begin
                uiSelEnd   := NewSelEnd;
                { ��������� ����� ������ }
                uiText := Copy(fLines[fStart.Y], fStart.X + 1, MAXINT);
                for n := fStart.Y + 1 to fEnd.Y do
                    uiText := uiText + #13#10 + fLines[n];
                System.SetLength(uiText, Length(uiText) - Length(fLines[fEnd.Y]) + fEnd.X);
            end;

        { ������ �������� ������ }
        Lines.BeginUpdate;
        for n := n2 - n1 downto 1 do
            if fStart.X = 0
                then Lines.Insert(fStart.Y, '')
                else Lines.Insert(fStart.Y + n1, '');
        for n := n1 - n2 downto 1 do
            Lines.Delete(fStart.Y);
        for n := 0 to n2 - 1 do
            Lines[fStart.Y + n] := Sl[n];

        // ������������� ����� ��������� �������
        fEnd := NewSelEnd;
        fStart := fEnd;
        fSealing := True;
        SetPos( fEnd );

        // ��������� � �����������
        Lines.EndUpdate;
    end;
    Sl.Free;
end;


// GetLength() ������������ ����� ������ ���������
function TMPSynMemoRange.GetLength: Integer;
var i: Integer;
begin
    Result := EndX - StartX;
    for i := StartY to EndY - 1 do
        Inc(Result, Length(fRichMemo.Lines[i]) + 2);
end;


// GetPosition() ��������� ������� ������ ��������� (0-based)
function TMPSynMemoRange.GetPosition: Integer;
begin
    Result := fRichMemo.Lines.RCToPosition(StartX, StartY);
end;


// SetLength() ������������� ����� ���������
procedure TMPSynMemoRange.SetLength(const Value: Integer);
var x0, dy, i, n: Integer;
begin
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} LogFmt('Range.SetLength(%d)', [Value]);
        {} {$ENDIF}
        dy := 0;
        x0 := StartX;
        n := Value;
        for i := StartY to fLines.Count - 1 do begin
            Dec(n, Length(fLines[i]) + 2 - x0);
            x0 := 0;
            if n <= 0 then begin
                Enlarge(dy, True);
                Enlarge(Length(fLines[i]) + 2 + n - StartX);
                Exit;
            end else
                Inc(dy);
        end;
    end;
end;


// SetPosition() ������������� ������� ������� �� ��� ������� �� ������ ������
procedure TMPSynMemoRange.SetPosition(const Value: Integer);
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Range.SetPosition(%d)', [Value]);
    {} {$ENDIF}
    Collapse;
    SetPos( fRichMemo.Lines.PositionToRC(Value) );
end;


// CanUndo() ���������� True, ���� ���� ����������� ������
function TMPSynMemoRange.CanUndo: Boolean;
begin
    Result := fUndoStack.Count > 0;
end;


// SetMaxUndoDepth() ������������� ����� ������� ����� ������
procedure TMPSynMemoRange.SetMaxUndoDepth(const Value: Integer);
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.LogFmt('Range.SetMaxUndoDepth(%d)', [Value]);
    {$ENDIF}
    while fMaxUndoDepth > Value do begin
        fUndoStack.Delete(0);
        Dec(fMaxUndoDepth);
    end;
    fMaxUndoDepth := Value;
end;


// SelectAll() �������� ���� �����
procedure TMPSynMemoRange.SelectAll;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.SelectAll');
    {$ENDIF}
    SetPosition(0);
    SetLength(Length(fRichMemo.Lines.Text));
end;


// SelectFromStart() �������� ����� �� ������ �� ������� �������
procedure TMPSynMemoRange.SelectFromStart;
var L: Integer;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.SelectFromStart');
    {$ENDIF}
    L := fRichMemo.Lines.RCToPosition(fPos.X, fPos.Y);
    SetPosition(0);
    SetLength(L);
end;


// SelectToEnd() �������� ����� �� ������� ������� �� ����� ���������
procedure TMPSynMemoRange.SelectToEnd;
var L: Integer;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.SelectToEnd');
    {$ENDIF}
    L := fRichMemo.Lines.RCToPosition(fPos.X, fPos.Y);
    SetPosition(L);
    SetLength(Length(fRichMemo.Lines.Text) - L);
end;



// Class TMPCustomSyntaxMemo methods implementation

// Create() �����������
constructor TMPCustomSyntaxMemo.Create(AOwner: TComponent);
var F: TFont;
begin
    inherited Create(AOwner);
    DoubleBuffered  := True;
    fLines          := TMPSynMemoStrings.Create(self);
    fRange          := TMPSynMemoRange.Create(self);
    fSections       := TMPSynMemoSections.Create(self);
    fParseAttributes:= TMPSyntaxAttributes.Create(self);
    fBookMarks      := TMPBookmarkManager.Create(self);
    fBuffer         := TBitmap.Create;
    Width           := 185;
    Height          := 89;
    Color           := clWindow;
    Cursor          := crIBeam;
    fSelWord        := Point(-1, -1);
    fDefBackColor   := clWindow;
    fDefForeColor   := clBlack;
    fSelColor       := clSkyBlue;
    fGutterWidth    := 32;
    fInsertMode     := True;

    fVScroll:= TScrollBar.Create(Self);
    with fVScroll do begin
        Parent      := Self;
        Kind        := sbVertical;
        OnChange    := ScrollClick;
        OnEnter     := ScrollEnter;
    end;

    fHScroll:= TScrollBar.Create(Self);
    with fHScroll do begin
        Parent      := Self;
        Kind        := sbHorizontal;
        Align       := alBottom;
        Ctl3D       := True;
        Visible     := True;
        OnChange    := ScrollClick;
        OnEnter     := ScrollEnter;
    end;

    // ��������� ����������� ���������� �� ���������
    F := TFont.Create;
    F.Name := 'Arial';
    F.Size := 9;
    F.Style := [];
    F.Color := clBlack;
    Font.Assign(F);
    F.Free;

    // ��������� ���������� �� ���������
    TabStop         := True;
    Font.OnChange   := FontChange;
    fSectionIndent  := 16;
end;


// Destroy() ����������
destructor TMPCustomSyntaxMemo.Destroy;
begin
    fScreenLines := nil;
    fBookMarks.Free;
    fBuffer.Free;
    fSections.Free;
    fParseAttributes.Free;
    fRange.Free;
    fLines.Free;
    inherited;
end;


// SetSelColor() ������������� ���� ���������
procedure TMPCustomSyntaxMemo.SetSelColor(const Value: TColor);
begin
    if Value <> fSelColor then begin
        fSelColor := Value;
        if not fRange.IsEmpty() then Invalidate;
    end;
end;


// ClientLines() ���������� ���������� ����� ������, ����������� � ���� ���������
function TMPCustomSyntaxMemo.ClientLines: Integer;
begin
    with TextRowRect[-1] do
        Result := (Bottom - Top + fCharHeight - 1) div fCharHeight;
end;


// WMSIZE() ������� �� ��������� �������� ���������
procedure TMPCustomSyntaxMemo.WMSIZE(var Message : TMessage);
begin
    Invalidate;
    CalcScreenParams;
    if not (csDesigning in ComponentState) then UpdateScrollBars;
end;


// CanResize() ������������ ������ ����� �������,
// ����� ���������� ������� ���� ������ ������ ������
function TMPCustomSyntaxMemo.CanResize(var NewWidth, NewHeight: Integer): Boolean;
begin
//    with TextRowRect[-1] do
//        Dec(NewHeight, (NewHeight - Self.Height + (Bottom - Top)) mod fCharHeight);
//    Inc(NewHeight);
    Result := Inherited CanResize(NewWidth, NewHeight);
end;


// ������� ������ ����� - ��������� �������� �����
procedure TMPCustomSyntaxMemo.WMLButtonDblClk(var Message : TWMMouse);
var Row, WIndex: Integer;
    Sec: TMPSynMemoSection;
    T: TMPSyntaxToken;
begin
    inherited;
    // ���� ������ ������� Ctrl �� ����� �������� ������,
    // ���������� ��������������� ������
    if (GetKeyState(VK_CONTROL) and $8000) <> 0 then begin
        WndOffsetToPixOffset(Point(Message.XPos, Message.YPos), WIndex, Row, True);
        if Lines.IsValidLineIndex(Row) then begin
            Sec := Sections.Section[Row];
            Sections.Expand(Row, False, True);
            Range.Collapse;
            { ��� ��� �������� ������ ���������� � -1, ������������ ����. ������ }
            Range.Pos := Point(0, EnsureRange(Sec.RowBeg, 0, Lines.Count - 1));
            Range.Enlarge(Sec.RowEnd - Sec.RowBeg + 1, True);
        end
    end else
    // �����, �������� ����� ��� ��������
    if GetWordAtPos(Message.XPos, Message.YPos, WIndex, Row) then
        if InRange(WIndex, 0, Lines.Parser[Row].Count - 1) then begin
            T := Lines.Parser[Row].Tokens[WIndex];
            Range.Collapse;
            Range.Pos := Point(T.stStart, Row);
            Range.Enlarge(T.stLength);
        end;
end;


// ���������� ���������� ������
procedure TMPCustomSyntaxMemo.CalcScreenParams;
var c: Char;
begin
    inherited;
    with Canvas do begin
        Font.Assign(Self.Font);
        FCharHeight := -Font.Height + 3;
        Font.Style  := [];
        for c := Low(fCharWidths[False]) to High(fCharWidths[False]) do
            fCharWidths[False][c] := Byte( TextWidth(c) );
        Font.Style  := [fsBold];
        for c := Low(fCharWidths[True]) to High(fCharWidths[True]) do
            fCharWidths[True][c] := Byte( TextWidth(c) );
    end;
    with fVScroll do begin
        Align       := alRight;
        Ctl3D       := True;
        Visible     := True;
    end;
    with fHScroll do begin
        Align       := alBottom;
        Ctl3D       := True;
        Visible     := True;
    end;
    SetLength(fScreenLines, ClientLines);
    with EntireRowRect[0] do begin
        fBuffer.Height := Bottom - Top;
        fBuffer.Width  := Right - Left;
    end;
end;


// ���������� �������� �� ������ ������ (� ��������)
function TMPCustomSyntaxMemo.CharPosToPixOffset(const Col: Integer; s: string; Sp: TMPSyntaxParser): Integer;
var T: TMPSyntaxToken;
    i, j, WordIndex: Integer;
    Bold: Boolean;
begin
    Result := 0;
    WordIndex := 0;
    i := 0;
    while WordIndex < Sp.Count do begin
        T := Sp[WordIndex];
        j := Min(Col, T.stStart);
        Inc(Result, (j - i) * fCharWidths[False][' ']);
        i := j;
        if i = Col then Break;
        Bold := fsBold in fParseAttributes.FontStyle[T.stToken];
        j := Min(Col, T.stStart + T.stLength);
        while i < j do begin
            Inc(Result, fCharWidths[Bold][s[i+1]]);
            Inc(i);
        end;
        if i = Col then Break;
        Inc(WordIndex);
    end;
    if i < Col then
        Inc(Result, (Col - i) * fCharWidths[False][' ']);
end;


// ���������� �������� �� ������ ������ (� ��������)
// ��� ��������� ������� (Col, 0-based) �������� ������ (Row, base=0)
function TMPCustomSyntaxMemo.CharPosToPixOffset(const Col, Row: Integer): Integer;
begin
    if fLines.IsValidLineIndex(Row) then
        Result := CharPosToPixOffset(Col, fLines[Row], fLines.Parser[Row])
    else
        Result := 0;
end;


// PixOffsetToCharPos() ���������� ����� ������� (0-based) ������� � ������ Row
// �� ��� �������� �� ������ ������ � �������� Pix
// ���� WordIndex <> nil, �� ����� ���� ������������ ������ ����� � ���� �������:
// WordIndex^ > 0, ���� ������� ������ �����
// WordIndex^ < 0, ���� ������� ����� ������ ������ (������ ����� �����������)
// WordIndex = MAXINT, ���� ������� ����� ���������� ����� � ������
function TMPCustomSyntaxMemo.PixOffsetToCharPos(const Pix, Row: Integer; const WordIndex: PInteger = nil): Integer;
var Sp: TMPSyntaxParser;
    s: string;
    Pos, WIndex: Integer;
    Bold: Boolean;
    T: TMPSyntaxToken;
begin
    Result := 0;
    if not InRange(Row, 0, fLines.Count - 1) then Exit;
    Sp := TMPSyntaxParser(fLines.Objects[Row]);
    s  := fLines[Row];
    WIndex := 0;
    Pos := 0;
    if Sp <> nil then
        while WIndex < sp.Count do begin
            T := Sp[WIndex];
            Bold := fsBold in fParseAttributes.FontStyle[T.stToken];
            while Result < T.stStart do begin
                Inc(Pos, fCharWidths[False][' ']);
                if Pos > Pix then begin
                    if Assigned(WordIndex) then WordIndex^ := -WIndex;
                    Exit;
                end;
                Inc(Result);
            end;
            while Result < T.stStart + T.stLength do begin
                Inc(Pos, fCharWidths[Bold][s[Result+1]]);
                if Pos > Pix then begin
                    if Assigned(WordIndex) then WordIndex^ := WIndex;
                    Exit;
                end;
                Inc(Result);
            end;
            Inc(WIndex);
        end;
    if Pos < Pix then
        Inc(Result, (Pix - Pos) div fCharWidths[False][' ']);
    if Assigned(WordIndex) then
        WordIndex^ := MAXINT;
end;


// WMGetDlgCode() ��� ����, ����� ��������� �� ����� ����� ��� ������� ����������� ������
procedure TMPCustomSyntaxMemo.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
   Message.Result := DLGC_WANTARROWS    // ��� �� ��� ������� ������� ����� �� �������}
                  or DLGC_WANTALLKEYS   // ��� �� ������� �� Enter ����������}
                  or DLGC_WANTTAB;
end;


// KeyDown() ��������� ������� ����������� ������
procedure TMPCustomSyntaxMemo.KeyDown(var Key: Word; Shift: TShiftState);
var xn, yn: Integer;
    {$IFDEF SYNDEBUG}
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
    {$ENDIF}
begin
    inherited;
    {$IFDEF SYNDEBUG}
    Log('KeyDown ' + IntToHex(Key, 2) + ' Shift: ' + ShiftAsString(Shift));
    {$ENDIF}
    with Range do
        case Key of
        VK_CONTROL:
            if (Shift = [ssCtrl]) and not fHinting then begin
                Cursor := crHandPoint;
                Hint := '';
                SelectedWord := Point(-1, -1);
                ShowHint := True;
                fHinting := True;
            end;

        VK_RIGHT:
            if not (ssShift in Shift) then begin
                Collapse;
                if not (ssCtrl in Shift) then
                    PosX := PosX + 1
                else
                if FindNextWord(xn, yn) then
                    Pos := Point(xn, yn);
            end else
                if not (ssCtrl in Shift)
                    then Enlarge(1)
                    else begin
                        if FindNextWord(xn, yn) then begin
                            Enlarge(yn - PosY, True);
                            Enlarge(xn - PosX);
                        end;
                    end;

        VK_LEFT:
            if not (ssShift in Shift) then begin
                Collapse;
                if not (ssCtrl in Shift) then
                    PosX := PosX - 1
                else
                if FindPrevWord(xn, yn) then
                    Pos := Point(xn, yn);
            end else
                if not (ssCtrl in Shift)
                    then Enlarge(-1)
                    else begin
                        if FindPrevWord(xn, yn) then begin
                            Enlarge(yn - PosY, True);
                            Enlarge(xn - PosX);
                        end;
                    end;

        VK_DOWN:
            if not (ssShift in Shift) then
                if not (ssCtrl in Shift)
                    then begin
                        Collapse;
                        PosY := FindVisibleRow(PosY, 1, True);
                    end else begin
                        OffsetY := FindVisibleRow(OffsetY, 1, True);
                        if StartY < OffsetY then begin
                            Collapse;
                            PosY := OffsetY;
                        end;
                    end
            else
                if not (ssCtrl in Shift)
                    then Enlarge(1, True, True)
                    else GotoSection(True);

        VK_UP:
            if not (ssShift in Shift) then
                if not (ssCtrl in Shift)
                    then begin
                        Collapse;
                        PosY := FindVisibleRow(PosY, -1, True);
                    end else begin
                        OffsetY := FindVisibleRow(OffsetY, -1, True);
                        if StartY >= OffsetY + ClientLines then begin
                            Collapse;
                            PosY := OffsetY + ClientLines - 1;
                        end;
                    end
            else
                if not (ssCtrl in Shift)
                    then Enlarge(-1, True, True)
                    else GotoSection(False);

        VK_HOME:
            if not (ssShift in Shift) then begin
                Collapse;
                if ssCtrl in Shift then PosY := 0;
                PosX := 0;
            end else begin
                if ssCtrl in Shift then Enlarge(-PosY, True);
                Enlarge(-PosX);
            end;

        VK_END:
            if not (ssShift in Shift) then begin
                Collapse;
                if ssCtrl in Shift then PosY := fLines.Count - 1;
                PosX := Length(fLines[PosY]);
            end else begin
                if ssCtrl in Shift then Enlarge(fLines.Count-1 - PosY, True);
                Enlarge(Length(fLines[PosY]) - PosX);
            end;

        VK_NEXT:
            if not (ssShift in Shift) then begin
                Collapse;
                if not (ssCtrl in Shift)
                    then PosY := FindVisibleRow(PosY, ClientLines - 1, True)
                    else PosY := FindVisibleRow(OffsetY, ClientLines - 1, True)
            end else
                if not (ssCtrl in Shift)
                    then Enlarge(ClientLines() - 1, True)
                    else Enlarge(OffsetY + (ClientLines - 1) - PosY, True);

        VK_PRIOR:
            if not (ssShift in Shift) then begin
                Collapse;
                if not (ssCtrl in Shift)
                    then PosY := FindVisibleRow(PosY, -(ClientLines - 1), True)
                    else PosY := OffsetY
            end else
                if not (ssCtrl in Shift)
                    then Enlarge( -(ClientLines - 1), True)
                    else Enlarge( -(OffsetY - PosY), True);

        VK_DELETE:
            if not (smoReadOnly in fOptions) then
                Range.Delete;

        VK_TAB:
            if not (smoReadOnly in fOptions) then
                Range.Text := StringOfChar(' ', 4 - PosX mod 4);

        VK_BACK:
            if not (smoReadOnly in fOptions) then begin
                if (PosX = 0) and (FindVisibleRow(Range.PosY, -1, True) = Range.PosY - 1) then
                    with Range do
                        Pos := Point(Length(fLines[PosY - 1]), PosY - 1)
                else
                if PosX > 0 then
                    PosX := PosX - 1;
                Range.Delete;
            end;

        VK_RETURN:
            if not (smoReadOnly in fOptions) then
                Range.Text := #13#10;

        VK_INSERT:
            if not (smoReadOnly in fOptions) then
                if smoOverwrite in fOptions
                    then SetOptions(fOptions + [smoOverwrite])
                    else SetOptions(fOptions - [smoOverwrite]);

        ORD('C'):
            if ssCtrl in Shift then
                fRange.CopyToClipboard;

        ORD('X'):
            if Shift = [ssCtrl] then
                fRange.CutToClipBoard;

        ORD('V'):
            if (Shift = [ssCtrl]) and not (smoReadOnly in fOptions) then
                fRange.PasteFromClipboard;

        ORD('Z'):
            if ssCtrl in Shift then
                if CanUndo then DoUndo;

        VK_ADD:
            if ssCtrl in Shift then
                fRange.ExpandSection(ssShift in Shift);

        VK_SUBTRACT:
            if ssCtrl in Shift then
                fRange.CollapseSection(ssShift in Shift);

        VK_F5:
            fRange.CreateSection;

        VK_F6:
            fRange.ExplodeSection(ssCtrl in Shift);

        Ord('0')..Ord('9'):
            if ssCtrl in Shift then
                if ssShift in Shift
                    then BookMarks[Key - Ord('0')] := fRange.PosY
                    else Navigate(0, BookMarks[Key - Ord('0')]);

        VK_NUMPAD0..VK_NUMPAD9:
            if ssCtrl in Shift then
                if ssShift in Shift
                    then BookMarks[Key - VK_NUMPAD0] := fRange.PosY
                    else Navigate(0, BookMarks[Key - VK_NUMPAD0]);

        {$IFDEF SYNDEBUG}
        VK_MULTIPLY:
            if ssCtrl in Shift then
                Log('---------------');
        {$ENDIF}

        end;
end;


// ������� ������� � ������� �������
procedure TMPCustomSyntaxMemo.KeyPress(var Key: Char);
begin
    inherited;
    case Key of
        #32..#255 : if not (smoReadOnly in fOptions) then
                        Range.Text := Key;
    end;
end;


// ���������� ������
procedure TMPCustomSyntaxMemo.KeyUp(var Key: Word; Shift: TShiftState);
begin
    Cursor := crIBeam;
    ShowHint := False;
    SelectedWord := Point(-1, -1);
    if Assigned(fOnWordInfo) then
        fOnWordInfo(self, 0, 0, -1, -1, False);
    fHinting := False;
    inherited;
end;


// Paint() ����������� ����� ����������
procedure TMPCustomSyntaxMemo.Paint;
begin
//    inherited;
    if Parent = nil then Exit;
    {} {$IFDEF SYNDEBUG}
    {} Log('Memo.Paint');
    {} {$ENDIF}
    NeedRedrawAll;
end;


// CreateParams() ������� ���������� ����������
procedure TMPCustomSyntaxMemo.CreateParams(var Params: TCreateParams);
begin
    inherited;
    with Params do begin
        ExStyle := ExStyle or WS_EX_CLIENTEDGE; // 3d ����� ����
        Style   := Style and not WS_TABSTOP;
    end;
end;


// WMMouseWheel() ��������� ������ ����
procedure TMPCustomSyntaxMemo.WMMouseWheel(var Message: TMessage);
begin
    inherited;
    if GetKeyState(VK_CONTROL) and $8000 <> 0 then
        if Short(HIWORD(Message.wParam)) > 0
            then OffsetXPix := Max(OffsetXPix - 4, 0)
            else OffsetXPix := OffsetXPix + 4
    else
        if Short(HIWORD(Message.wParam)) > 0
            then OffsetY := FindVisibleRow(OffsetY, -1, True)
            else OffsetY := FindVisibleRow(OffsetY, +1, True);
end;


// WMKillFocus() ��������� ������ ������
procedure TMPCustomSyntaxMemo.WMKillFocus(var Msg: TWMKillFocus);
begin
    inherited;
    if (Msg.FocusedWnd <> fHScroll.Handle)
    and (Msg.FocusedWnd <> fVScroll.Handle) then begin
        HideCaret;
        Windows.DestroyCaret;
    end;
end;


// WMSetFocus() ��������� ��������� ������
procedure TMPCustomSyntaxMemo.WMSetFocus(var Msg: TWMSetFocus);
begin
    inherited;
    if (Msg.FocusedWnd <> fHScroll.Handle)
    and (Msg.FocusedWnd <> fVScroll.Handle) then begin
        Windows.CreateCaret(Handle, 0, 1, FCharHeight);
        ShowCaret;
    end;
end;


// ScrollEnter() ��������� � ���������
procedure TMPCustomSyntaxMemo.ScrollEnter(Sender: TObject);
begin
    SetFocus;
end;


// MouseDown() ������� ������ ����
procedure TMPCustomSyntaxMemo.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var Col, Row, SRow: Integer;
    R: TRect;
begin
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('MouseDown at (%d, %d)', [X, Y]);
    {} {$ENDIF}
    if not Focused then SetFocus;
    { ����� ������ ���� }
    if (Button = mbLeft) and (Shift = [ssLeft]) then
        if PtInRect(EntireGutterRect[-1], Point(X, Y)) then begin
            { ������ ������ � ������� - ��������� ������� / ��������� ������ }
            WndOffsetToPixOffset(Point(X, Y), Col, SRow, False);
            Row := FindVisibleRow(OffsetY, SRow, False);
            with fSections.Section[Row] do
                if (Level > 0) and (Row = RowBeg) then begin
                    R := GetSectionButtonRect(SRow, Level);
                    if PtInRect(R, Point(X, Y)) then
                        if Collapsed
                            then fSections.Expand(Row, False, False)
                            else fSections.Collapse(Row, False, False);
                end;
        end else begin
            fDown := True;
            { ������� ��������� }
            Range.Collapse;
            WndOffsetToPixOffset(Point(X, Y), Col, Row, True);
            if fLines.IsValidLineIndex(Row) then begin
                Col := PixOffsetToCharPos(Col, Row);
                Range.Pos := Point(Col, Row);
            end;
        end
    else
    { ������� ������ ���� - ��������������� (!!!) }
    if (Button = mbMiddle) and (Shift = [ssMiddle]) then begin
        fPanning := True;
        Cursor := crSizeAll;
        WndOffsetToPixOffset(Point(X, Y), fPanStartPoint.X, fPanStartPoint.Y, False);
    end;
    inherited;
end;



 // MouseMove() �������� ���� - ��������� ��������� ���������
procedure TMPCustomSyntaxMemo.MouseMove(Shift: TShiftState; X, Y: Integer);
var Col, Row: Integer;
begin
    // ���������� ����������
    if fDown and (Shift = [ssLeft]) then begin
        // ���������� ��������� ������ ���� ��������� �������
        WndOffsetToPixOffset(Point(X, Y), Col, Row, True);
        Col := PixOffsetToCharPos(Col, Row);
        if (Col <> Range.PosX) or (Row <> Range.PosY) then begin
            Range.Enlarge(Row - Range.PosY, True);
            Range.Enlarge(Col - Range.PosX);
        end;
    end else
    // ���������������
    if fPanning and (Shift = [ssMiddle]) then begin
        WndOffsetToPixOffset(Point(X, Y), Col, Row, False);
        if Row <> fPanStartPoint.Y then begin
            OffsetY := FindVisibleRow(OffsetY, fPanStartPoint.Y  - Row, True);
            fPanStartPoint.Y := Row;
        end;
        if Col <> fPanStartPoint.X then
            OffsetXPix := OffsetXPix + fPanStartPoint.X - Col;
    end else
    if fHinting then begin
        WndOffsetToPixOffset(Point(X, Y), Col, Row, True);
        PixOffsetToCharPos(Col, Row, @Col);
        if InRange(Col, 0, fLines.Parser[Row].Count - 1) then begin
            SelectedWord := Point(Col, Row);
            if Assigned(fOnWordInfo) then
                fOnWordInfo(self, X, Y, Col, Row, True)
            else
                with fLines.Parser[Row].Tokens[Col] do
                    Hint := Format('Word: "%s"'#13#10'Start: %d'#13#10'Length: %d'#13#10'As token #%d', [Copy(fLines[Row], stStart + 1, stLength), stStart, stLength, stToken]);
        end
    end else
    if Shift = [] then begin
        if PtInRect(EntireGutterRect[-1], Point(X, Y))
            then Cursor := crDefault
            else Cursor := crIBeam;
    end;
    inherited;
end;



 // MouseUp() ���������� ������ ����
procedure TMPCustomSyntaxMemo.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    inherited;
    if fPanning then begin
        fPanning := False;
        Cursor := crIBeam;
    end;
    fDown := False;
end;


// FindNextWord() ���� ��������� �����.
// ���� ����� ������� (�� ����� ������), ��� ������ ������������
// ����� ������ wx, wy
function TMPCustomSyntaxMemo.FindNextWord(var wx, wy: Integer): Boolean;
var Sp: TMPSyntaxParser;
begin
    Result := True;
    wx := CharPosToWordIndex(Range.PosX, Range.PosY);
    wy := Range.PosY;
    Sp := fLines.Parser[wy];
    { ������ ����� ������� � �������� ������ }
    if wx < 0 then begin
        wy := Range.PosY;
        wx := Sp[-wx].stStart;
    end else
    { ������ ����� ���������� ����� � ������ }
    if wx = MAXINT then begin
        wy := FindVisibleRow(wy, 1, False);
        Result := wy >= 0;
        if Result then begin
            Sp := fLines.Parser[wy];
            if Sp.Count > 0
                then wx := Sp[0].stStart
                else wx := 0;
        end
    end else
    { ������ �� ��������� ����� � ������ }
    if wx = Sp.Count - 1 then
        with Sp[wx] do
            wx := stStart + stLength
    { ������ �� ����� ������ ����� � ������ }
    else
        wx := Sp[wx + 1].stStart;
end;


// FindPrevWord() ���� ����������� �����.
// ���� ����� ������� (�� ������ ������), ��� ������ ������������
// ����� ������ wx, wy
function TMPCustomSyntaxMemo.FindPrevWord(var wx, wy: Integer): Boolean;
var Sp: TMPSyntaxParser;
    function FindLastWordOfPrevRow: Boolean;
    begin
        wy := FindVisibleRow(wy, -1, False);
        Result := wy >= 0;
        if Result then begin
            Sp := fLines.Parser[wy];
            if Sp.Count > 0
                then
                    with Sp[Sp.Count - 1] do
                        wx := stStart + stLength
                else wx := 0;
        end;
    end;
begin
    Result := True;
    wx := CharPosToWordIndex(Range.PosX, Range.PosY);
    wy := Range.PosY;
    Sp := fLines.Parser[wy];
    { ������ ����� ������� � �������� ������ }
    if wx < 0 then
        { ����� ������ ������ - ����� ������ ��� }
        if wx = -1
            then Result := FindLastWordOfPrevRow
            else wx := Sp[-wx - 1].stStart
    else
    { ����� ���������� ����� � ������ }
    if wx = MAXINT then
        if Sp.Count = 0
            then Result := FindLastWordOfPrevRow
            else wx := Sp[Sp.Count-1].stStart
    else
    { ������ ������������� ����� � ������ }
    if Sp[wx].stStart = Range.PosX then
        { � ������ ����� }
        if wx = 0
            then Result := FindLastWordOfPrevRow
            else wx := Sp[wx - 1].stStart
    else
        { � �������� ����� }
        wx := Sp[wx].stStart;
end;


// PaintLine() �������������� ������
(*procedure TMPCustomSyntaxMemo.PaintLine(const ScreenRow, Row: Integer);
var CharPos, WIndex, SelIndeXFrom, SelIndeXTo, i: Integer;
    T: TMPSyntaxToken;
    s: string;
    PaintOffset, SecPnt: TPoint;
    ClipRgn: HRGN;
    RowRect, WordRect, R: TRect;
    Sp: TMPSyntaxParser;
    Sec: TMPSynMemoSection;
begin
    // ���� ��������� �� ����� - ���� � �������������� ���?
    if not Visible then Exit;

    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.PaintLine %d as %d', [ScreenRow, Row]);
    {} {$ENDIF}

    // ��������� ������
    RowRect := TextRowRect[ScreenRow];

    // ������������ GUTTER
    with Canvas do begin
        // �������� ������� Gutter-a
        if smoVSNET_SectionsStyle in fOptions
            then R := SymbolsGutterRect[ScreenRow]
            else R := EntireGutterRect[ScreenRow];
        Brush.Style := bsSolid;
        Brush.Color := clBtnFace;
        Dec(R.Right, 4);
        FillRect( R );
        // Bevel Edge ������ Gutter-a
        Pen.Color := clBtnHighlight;
        MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
        Pen.Color := clBtnShadow;
        MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
        Pen.Color := self.Color;
        MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
        MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
        // ������ ������
        Canvas.Brush.Color := Self.Color;
        FillRect(Rect(R.Right, RowRect.Top, RowRect.Right, RowRect.Bottom));

        // ���� ����� ������ ������������ (����. ������ ����� ������)
        // �� ������ ��� ������� � �������
        if Row < 0 then Exit;

        // ��������� �������������� ������ ������
        Sp := fLines.Parser[Row];                           // ������ ������
        Sec := Sp.Section;                                  // ������ ������
        s := fLines[Row];                                   // ������
        R := GetSectionButtonRect(ScreenRow, Sec.Level);    // ��������
        SecPnt := CenterPoint(R);                           // ����������� ����� ���������

        // ������ ������ - ������������� ��������
        if (Sec.RowBeg = Row) and (Sec.Level > 0) then begin
            if Sec.Collapsed then begin
                Brush.Color := clWhite;
                Pen.Color   := clBlack;
                Rectangle(R);
            end else begin
                Brush.Color := clBlack;
                FrameRect(R);
            end;
            Pen.Color := clBlack;
            with R do begin
                MoveTo(Left + 2, SecPnt.Y);
                LineTo(Right - 2, SecPnt.Y);
                if Sec.Collapsed then begin
                    MoveTo(SecPnt.X, Top + 2);
                    LineTo(SecPnt.X, Bottom - 2);
                end;
                Pen.Color := clDkGray;
                // ����� ������ �� ���������
                MoveTo(Right, SecPnt.Y);
                LineTo(RowRect.Left - 2, SecPnt.Y);
                if not Sec.Collapsed then begin
                    // ����� ����� ���������
                    MoveTo(SecPnt.X, Bottom);
                    LineTo(SecPnt.X, RowRect.Bottom);
                end;
            end;
            // ������������ ��������� � ����� ������
            if Sec.Collapsed then begin
                R := RowRect;
                Inc(R.Top, 1);
                Dec(R.Bottom, 1);
                R.Left := R.Right - 32;
                R.Right := R.Left + 22;
                Brush.Color := clBlue;
                FrameRect(R);
                R := Bounds(R.Left + 5, R.Top + 8, 2, 2);
                FillRect(R);
                OffsetRect(R, 5, 0);
                FillRect(R);
                OffsetRect(R, 5, 0);
                FillRect(R);
            end;
        end else

        // ����� ������ - ������ �����. �������
        if (Sec.RowEnd = Row) and (Sec.Level > 0) then begin
            Pen.Color := clDkGray;
            MoveTo(SecPnt.X, RowRect.Top);
            LineTo(SecPnt.X, SecPnt.Y);
            LineTo(RowRect.Left - 2, SecPnt.Y);
        end else

        // ������ ������, ������������� ��-�������� ������
        if Sec.Level > 0 then begin
            Pen.Color := clDkGray;
            MoveTo(SecPnt.X, RowRect.Top);
            LineTo(SecPnt.X, RowRect.Bottom);
        end;

        // ��������� ������������ ����� ������������ ������
        // ������ �� ��� ������ �������� MS VS NET
        if not (smoVSNET_SectionsStyle in fOptions) then
            for i := Sec.Level - 1 downto 1 do begin
                Dec(SecPnt.X, fSectionIndent);
                MoveTo(SecPnt.X, RowRect.Top);
                LineTo(SecPnt.X, RowRect.Bottom);
            end;

        // ������������ � ������������� Clip Region ��� ����� ������
        with RowRect do
            if Sec.Collapsed
                then ClipRgn := CreateRectRgn(Left, Top, Right - 33, Bottom)
                else ClipRgn := CreateRectRgn(Left, Top, Right, Bottom);
        SelectClipRgn(Canvas.Handle, ClipRgn);

        // �������� ��� ������ ������ (X<=0 !!!)
        PaintOffset := PixOffsetToWndOffsetEx(0, ScreenRow);

        // ����������� ���������
        if not Range.IsEmpty() and InRange(Row, Range.StartY, Range.EndY) then begin
            // ���� ������ = ������ ������ ���������, �� ������������ � ����� ��������,
            // �����, ��������� � �� ������ ������� ������� ������ (OffsetX)
            if Row = Range.StartY
                then SelIndeXFrom := PaintOffset.X + CharPosToPixOffset(Range.StartX, Row)
                else SelIndeXFrom := RowRect.Left;
            // ���������� ������������ � ������ �������� ���������
            if Row = Range.EndY
                then SelIndeXTo   := PaintOffset.X + CharPosToPixOffset(Range.EndX, Row)
                else SelIndeXTo   := RowRect.Right;
            // ������ ���������
            Canvas.Brush.Style := bsSolid;
            Canvas.Brush.Color := fSelColor;
            Canvas.FillRect( Rect(SelIndeXFrom, RowRect.Top, SelIndeXTo, RowRect.Bottom) );
        end;

        // ������, �� �������, ��� �����
        if Assigned(Sp) then
            with Canvas do begin
                Brush.Style := bsClear;
                Pen.Color := clRed;
                Font.Assign(Self.Font);
                PenPos := PaintOffset;
                CharPos := 0;
                for WIndex := 0 to Sp.Count - 1 do begin
                    T := Sp[WIndex];
                    with fParseAttributes.fTokenStyles[T.stToken] do begin
                        Font.Color := tsForeground;
                        Font.Style := tsStyle;
                    end;
                    WordRect.TopLeft := PenPos;
                    Inc(WordRect.Left, (T.stStart - CharPos) * fCharWidths[False][' ']);
                    TextOut(WordRect.Left, WordRect.Top, Copy(s, T.stStart + 1, T.stLength));
                    WordRect.Right := PenPos.X;
                    WordRect.Bottom := WordRect.Top + fCharHeight - 1;
                    if (fSelWord.X = WIndex) and (fSelWord.Y = Row) then
                        Rectangle( WordRect );
                    CharPos := T.stStart + T.stLength;
                end;
            end;

        // �������� Clip Region ��� ����� ������
        SelectClipRgn(Canvas.Handle, 0);
        DeleteObject(ClipRgn);
    end;
end;    *)


// ������������� ��������� ����������, ���� ��������� �����
procedure TMPCustomSyntaxMemo.FontChange(Sender: TObject);
begin
    fLines.BeginUpdate;
    CalcScreenParams;
    NeedRedrawAll;
    fLines.EndUpdate;
end;


// �������������/������� ��������� ��� ����������� ����� � ������ (������� �����)
procedure TMPCustomSyntaxMemo.SetSelectedWord(const Value: TPoint);
begin
    fLines.BeginUpdate;
    // ������� ������ ���������
    if fLines.IsValidLineIndex( fSelWord.Y ) then
        NeedRedraw(fSelWord.Y);
    // ���������� ���������
    fSelWord := Point(-1, -1);
    // ������������� ����� ���������
    if fLines.IsValidLineIndex( Value.Y ) then begin
        // ������������� �������� ���, ����� ���������� ����� ���� ������� �� ������
        ShowWord(Value.Y, Value.X);
        // ���� ��������� ��������� - ��� ������ � ����
        fSelWord := Value;
        NeedRedraw(fSelWord.Y);
    end;
    fLines.EndUpdate;
end;


// ���������� ����� �� ������ (������������ ��������������� �������� ������)
procedure TMPCustomSyntaxMemo.ShowWord(const Row, WordIndex: Integer);
begin
    {$IFDEF SYNDEBUG}
    LogFmt('Memo.ShowWord Row=%d; WordIndex=%d)', [Row, WordIndex]);
    {$ENDIF}
    if fLines.IsValidLineIndex(Row) then
        with fLines.Parser[Row] do
            if InRange(WordIndex, 0, Count - 1) then
                with Tokens[WordIndex] do
                    MakeVisible(stStart, Row, stLength);
end;


// ���������� ���������� � ����� � ������� X, Y ������������ ����
// LineIndex - ����� ������
// WBeg      - ����� ������� ������� ����� � ������
// WLen      - ����� �����
function TMPCustomSyntaxMemo.GetWordAtPos(const X, Y: Integer; var WordIndex, Row: Integer): Boolean;
var n, Row1: Integer;
begin
    WndOffsetToPixOffset(Point(X, Y), n, Row1, True);
    Result := fLines.IsValidLineIndex(Row1);
    if Result then begin
        Row := Row1;
        PixOffsetToCharPos(n, Row1, @WordIndex);
    end;
end;


// ������������� ������� ������ Row, ������� Col,
// ��� ������������� �������� ��������������� ������
procedure TMPCustomSyntaxMemo.Navigate(const Col, Row: Integer);
begin
    if not fLines.IsValidLineIndex(Row) then Exit;
    {$IFDEF SYNDEBUG}
    LogFmt('Memo.NavigateTo Col=%d; Row=%d', [Col, Row]);
    {$ENDIF}
    fLines.BeginUpdate;
    fSections.Expand(Row, False, True);
    SetOffsets(Point(0, FindVisibleRow(Row, -2, True)));
    fRange.Pos := Point(Col, Row);
    fLines.EndUpdate;
end;


// ������������� ������� ������� ������� PosX � ������ PosY
procedure TMPCustomSyntaxMemo.MakeVisible(const Col, Row: Integer; const Length: Integer = 1);
var RowPix, CharPix, CharPixLen: Integer;
    NewOffsets: TPoint;
    R: TRect;
begin
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.MakeVisible(Col=%d; Row=%d; Length=%d)', [Col, Row, Length]);
    {} {$ENDIF}

    // ���������
    RowPix := RangeRowToScreenRow(Row);
    if RowPix = ROW_HIDEN then Exit else
    if RowPix = ROW_ABOVE_SCREEN then NewOffsets.Y := Row else
    if RowPix = ROW_BELOW_SCREEN then
        NewOffsets.Y := FindVisibleRow(Row, -(ClientLines - 1), True)
    else
        NewOffsets.Y := OffsetY;

    // �����������
    R := TextRowRect[0];
    CharPixLen := Length * 10;
    CharPix := CharPosToPixOffset(Col, Row);
    if CharPix < OffsetXPix then NewOffsets.X := CharPix else
    if CharPix + CharPixLen - OffsetXPix > R.Right - R.Left then
        NewOffsets.X := CharPix + CharPixLen - R.Right + R.Left
    else
        NewOffsets.X := OffsetXPix;

    // ��� ������
    if (NewOffsets.X <> OffsetXPix) or (NewOffsets.Y <> OffsetY) then
        SetOffsets(NewOffsets);
end;


// ���������� ������ ����� � ������ �� ������� �������
// ���� �������� � ������� - ���������� ������������� �������� ������� ���������� ����� ������
// ���� ��� ������ - ���������� MAXINT
function TMPCustomSyntaxMemo.CharPosToWordIndex(const Col, Row: Integer): Integer;
var Sp: TMPSyntaxParser;
    i, WBeg: Integer;
begin
    Result := MAXINT;
    if not InRange(Row, 0, fLines.Count - 1) then Exit;
    Sp := TMPSyntaxParser(fLines.Objects[Row]);
    if Sp <> nil then
        for i := 0 to Sp.Count - 1 do begin
            WBeg := Sp[i].stStart;
            if Col < WBeg then begin
                Result := -i;
                Exit;
            end else
            if Col < WBeg + Sp[i].stLength then begin
                Result := i;
                Exit;
            end;
        end;
end;


// ���������� ���������� �� ����������� ����������������� �����
function TMPCustomSyntaxMemo.GetUserTokenEvent: TUserTokenEvent;
begin
    if Assigned(fParseAttributes)
        then Result := fParseAttributes.OnUserToken
        else Result := nil;
end;


// ������������� ���������� �� ����������� ����������������� �����
procedure TMPCustomSyntaxMemo.SetUserTokenEvent(const Value: TUserTokenEvent);
begin
    if Assigned(fParseAttributes) then
        fParseAttributes.OnUserToken := Value;
end;


// ������������� ������ GUTTER-�
procedure TMPCustomSyntaxMemo.SetGutterWidth(const Value: Integer);
begin
    if fGutterWidth <> Value then begin
        fGutterWidth := Value;
        Repaint;
    end;
end;


// ���������� ������, ���� ������ ������������ �� ������
function TMPCustomSyntaxMemo.IsLineVisible(const Row: Integer; const PScreenRow: PInteger = nil): Boolean;
var sr: Integer;
begin
    sr := RangeRowToScreenRow(Row);
    Result := InRange(sr, 0, ClientLines - 1);
    if Result and Assigned(PScreenRow) then
        PScreenRow^ := sr;
end;


// ������������� ����� �������� ��� ������ ������
procedure TMPCustomSyntaxMemo.SetSectionIndent(const Value: Integer);
begin
    fSectionIndent := Value;
    NeedRedrawAll;
end;


// ���������� ������������� �������� ��������� �������� �������
// ���������� �������. ������ ���� ���������� ��� ��������� ������� ����������
// ��������� ����������� ��� ������.
// �� ����� - �������� ������ ������ (������������ ������� ������ ������).
// ���� ScreenRow = -1, ������������ ��������������� ������� ����.
// �� ���������� �������� ��������� ������ � ����, ��� ������ ��������� � �������� ������
function TMPCustomSyntaxMemo.GetWndRect(const ScreenRow, Index: Integer): TRect;
begin
    if smoVSNET_SectionsStyle in fOptions then
        case Index of

        { EntireRowRect }
        0:  begin
                if ScreenRow = -1 then begin
                    { ��� ���� ����� ����� }
                    Result := ClientRect;
                    Dec(Result.Bottom, fHScroll.Height);
                end else
                    { ��� �������� ������ }
                    Result := Bounds(   0,
                                        ScreenRow * fCharHeight,
                                        ClientWidth,
                                        Min(fCharHeight, ClientHeight - fHScroll.Height - ScreenRow * fCharHeight)  );
//                                      fCharHeight );
                Dec(Result.Right, fVScroll.Width);
                Dec(Result.Right);
            end;

        { TextRowRect }
        1:  begin
                Result := EntireRowRect[ScreenRow];
                Result.Left := EntireGutterRect[ScreenRow].Right;
            end;

        { EntireGutterRect }
        2:  begin
                Result := SymbolsGutterRect[ScreenRow];
                Inc(Result.Right, fSectionIndent + 2);
            end;

        { SymbolsGutterRect }
        3:  begin
                Result := EntireRowRect[ScreenRow];
                Result.Right := Result.Left + fGutterWidth;
            end;
        end

    else
        case Index of

        { EntireRowRect }
        0:  begin
                if ScreenRow = -1 then begin
                    { ��� ���� ����� ����� }
                    Result := ClientRect;
                    Dec(Result.Bottom, fHScroll.Height);
                end else
                    { ��� �������� ������ }
                    Result := Bounds(
                        0,
                        ScreenRow * fCharHeight,
                        ClientWidth,
                        Min(fCharHeight, ClientHeight - fHScroll.Height - ScreenRow * fCharHeight)  );
                Dec(Result.Right, fVScroll.Width);
                Dec(Result.Right);
            end;

        { TextRowRect }
        1:  begin
                Result := EntireRowRect[ScreenRow];
                Result.Left := EntireGutterRect[ScreenRow].Right;
            end;

        { EntireGutterRect }
        2:  begin
                Result := EntireRowRect[ScreenRow];
                if smoAutoGutterWidth in fOptions
                    then Result.Right := Result.Left + fGutterWidth + fSections.fMaxExpandLevel*fSectionIndent + 2
                    else Result.Right := Result.Left + fGutterWidth + fSections.fMaxLevel*fSectionIndent + 2;
            end;

        { SymbolsGutterRect }
        3:  begin
                Result := EntireRowRect[ScreenRow];
                Result.Right := Result.Left + fGutterWidth;
            end;
        end;
end;


// ����������� ������� X, Y ���������� �������
// � �������� �� ������ ������ � ����� ������ ������
procedure TMPCustomSyntaxMemo.WndOffsetToPixOffset(OfsPoint: TPoint; var CharPix, Row: Integer; const TextRow: Boolean);
var R: TRect;
begin
    R := TextRowRect[ 0 ];
    CharPix := OfsPoint.X - R.Left + OffsetXPix;
    // �������� ������ ������ �� ������ ..
    Row := (OfsPoint.Y - R.Top) div fCharHeight;
    // .. �, ���� ����, ��������� ��� � �������� ������ ������ � ������
    if TextRow then
        Row := FindVisibleRow(OffsetY, Row, False);
end;


// ����������� �������� � �������� ������ ������ � �����������
// ������ ���������� ������� ����
function TMPCustomSyntaxMemo.PixOffsetToWndOffsetEx(const CharPix, ScreenRow: Integer): TPoint;
begin
    with TextRowRect[ ScreenRow ] do begin
        Inc(Left, CharPix - OffsetXPix);
        Result := TopLeft;
    end;
end;


// ���������� ������� ���������� ��������� ��������� ������ ����� R: TRect
// ���� ��������� ���, ������������ False
function TMPCustomSyntaxMemo.GetSectionButtonRect(const ScreenRow, ALevel: Integer): TRect;
begin
    // ������� Guttera ��� ������ ������
    Result := SymbolsGutterRect[ScreenRow];
    if smoVSNET_SectionsStyle in fOptions
        // ��� ���������� �� ����� �����
        then Result.Left := Result.Right + 2
        // ������� ��������� �� ����������� ������ ������ SectionIndent
        else Result.Left   := Result.Right + (ALevel - 1)*fSectionIndent;
    Result.Right  := Result.Left + 9;
    Result.Top    := (Result.Top + Result.Bottom) shr 1 - 4;
    Result.Bottom := Result.Top + 9;
end;


// ������ ������
procedure TMPCustomSyntaxMemo.HideCaret;
begin
    if fCaretVisible and Assigned(Parent) then begin
        Windows.HideCaret(Handle);
        fCaretVisible := False;
    end;
end;


// ���������� ������
procedure TMPCustomSyntaxMemo.ShowCaret;
var n, ScreenRow: Integer;
    Cp: TPoint;
begin
    if  (Lines.UpdateCount = 0)
    and Lines.IsValidLineIndex(Range.PosY)
    and IsLineVisible(Range.PosY, @ScreenRow) then begin
        n := CharPosToPixOffset(Range.PosX, Range.PosY);
        Cp := PixOffsetToWndOffsetEx(n, ScreenRow);
        Windows.SetCaretPos(Cp.X, Cp.Y);
        Windows.ShowCaret(Handle);
        fCaretVisible := True;
    end;
end;


// RangeRowToScreenRow() ��������� �������� ������ ������ � �������� � ������ ������������.
// ���� �������� ��������� �� ���������� (���� ������� ������� ������), ������������ -1
// ���� ������ �� ����� (� ��������� ������), ������������ -2;
// ���� ������ ���� ������ ������� ������, ������������ -3
// ������������ ������ ������ ������������ ������� ������ ������.
function TMPCustomSyntaxMemo.RangeRowToScreenRow(const Row: Integer): Integer;
begin
    // �������� ������ ������ ������ ���� ������ ��� ����� ������� �������� OffsetY,
    // ����� ��� ����� �� ����� �� ������ + ������ �� ������ ���� ��������� [loLatent]
    if Row < OffsetY then
        Result := ROW_ABOVE_SCREEN
    else
    if fLines.Parser[Row].VisibleIndex < 0 then
        Result := ROW_HIDEN
    else begin
        Result := RowIndexConvert(Row, cdNeedScreen) - RowIndexConvert(OffsetY, cdNeedScreen);
        if Result >= ClientLines then
            Result := ROW_BELOW_SCREEN;
    end;
end;


// FindVisibleRow() ���� ������� ������ �� �������� Delta ������� ����� �� ��������.
// Delta ����� ���� >=0 ��� <0.
// ���� EnsureInRange = True, ��������� ����� ������ � �������� ������,
// ����� ��� ������ �� ������� ������, ������� ������ -1
function TMPCustomSyntaxMemo.FindVisibleRow(const Row, Delta: Integer; const EnsureInRange: Boolean): Integer;
var n: Integer;
begin
    // ������� ������ ������� ������
    n := RowIndexConvert(Row, cdNeedScreen) + Delta;
    if EnsureInRange then
        n := EnsureRange(n, 0, fSections.Indexes.Count - 1);
    Result := RowIndexConvert(n, cdNeedReal);
end;


// RowIndexConvert() ������������ ������� ������ ������ � �������� � ��������
function TMPCustomSyntaxMemo.RowIndexConvert(const Index: Integer; const Direction: TRowIndexConvertionDirection): Integer;
begin
    Result := -1;
    case Direction of
    cdNeedReal:     if InRange(Index, 0, fSections.Indexes.Count - 1)
                        then Result := Integer(fSections.Indexes[Index]);

    cdNeedScreen:   if fLines.IsValidLineIndex(Index)
                        then Result := fLines.Parser[Index].VisibleIndex;
    end;
end;


// ��������� ScrollBar-� ���������� � ����������� �� ���������� ������
// � ������� ������� �������
procedure TMPCustomSyntaxMemo.UpdateScrollBars;
var i, MaxLine: Integer;
begin
    {} {$IFDEF SYNDEBUG}
    {} Log('Memo.UpdateScrollBars');
    {} {$ENDIF}
    // ����� ���� ��� ������� ��� ����� �������� ���������
    if (Parent = nil) or (Lines.UpdateCount > 0) then Exit;

    // �������� ��������� ������������ ������, ���� ��� ���������
    fVScroll.OnChange := nil;
    with fVScroll do begin
        Max := Math.Max(fSections.Indexes.Count - ClientLines, 0);
        Enabled := Max > 0;
        if fLines.Count = 0
            then Position := 0
            else Position := RowIndexConvert(OffsetY, cdNeedScreen);
        SmallChange := 1;
        LargeChange := ClientLines - 2;
    end;

    // �������� ��������� �������������� ������, ���� ��� ���������
    fHScroll.OnChange := nil;
    with fHScroll do begin
        MaxLine := 0;
        for i := 0 to fLines.Count-1 do
            if Length(fLines[i]) > MaxLine then MaxLine := Length(fLines[i]);
        // SLAB - 10 ����� � �������
        with TextRowRect[-1] do
            Max := Math.Max(MaxLine * 10 - (Right - Left), 0);
        Enabled := Max > 0;
        Position := OffsetXPix;
        SmallChange := 1;
        LargeChange := 32;
    end;

    // ��� ���������������
    fVScroll.OnChange := ScrollClick;
    fHScroll.OnChange := ScrollClick;
end;


// ������ �� ����������
procedure TMPCustomSyntaxMemo.ScrollClick(Sender: TObject);
begin
    if Sender = fVScroll
        then OffsetY := RowIndexConvert(fVScroll.Position, cdNeedReal)
        else OffsetXPix := fHScroll.Position;
end;



 // SetOffset() ������������� ��� �������� ������ �����
// (��� ���������� ���������� �����������)
procedure TMPCustomSyntaxMemo.SetOffsets(NewOffsets: TPoint);
begin
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.SetOffsets Pix=%d; Row=%d', [NewOffsets.X, NewOffsets.Y]);
    {} {$ENDIF}
    { �������� �� ������������ ����� �������� }
    // OffsetXPix
    if NewOffsets.X <> fOffsets.X then
        NewOffsets.X := EnsureRange(NewOffsets.X, 0, fHScroll.Max);
    // OffsetY
    if NewOffsets.Y <> fOffsets.Y then begin
        NewOffsets.Y := EnsureRange(RowIndexConvert(NewOffsets.Y, cdNeedScreen), 0, fVScroll.Max);
        NewOffsets.Y := RowIndexConvert(NewOffsets.Y, cdNeedReal);
    end;
    { �������� ������������ �������� � �����������, ���� ��� ������������� ��������� }
    if (NewOffsets.X <> fOffsets.X) or (NewOffsets.Y <> fOffsets.Y) then begin
        fOffsets := NewOffsets;
        NeedRedrawAll;
        UpdateScrollBars;
    end;
end;


// SetOffset() ������������� �������� ������ ������������ ���� ����������
// � ����������� �� ��������� ��� �����������.
procedure TMPCustomSyntaxMemo.SetOffset(const Index, Value: Integer);
begin
    case Index of
    0:  SetOffsets(Point(Value, fOffsets.Y));
    1:  SetOffsets(Point(fOffsets.X, Value));
    end;
end;


// Reset() ���������� ���������
procedure TMPCustomSyntaxMemo.Reset;
begin
    {$IFDEF SYNDEBUG}
    Log('Reset');
    {$ENDIF}
    { Self }
    fOffsets        := Point(0, 0);
    fDown           := False;
    fPanning        := False;
    fOptions        := fOptions - [smoOverwrite, smoReadOnly];
    fBookMarks.Clear;
    { Range }
    fRange.fPos     := fOffsets;
    fRange.fStart   := fOffsets;
    fRange.fEnd     := fOffsets;
    fRange.fSealing := True;
    fRange.fUndoStack.Clear;
end;


// SetOption() ������������� �����
procedure TMPCustomSyntaxMemo.SetOptions(const Value: TMPSynMemoOptions);
var oi: TMPSynMemoOption;
    os: TMPSynMemoOptions;
    new: Boolean;
begin
    if fOptions <> Value then begin
        // ������� ������ �����
        os := fOptions;
        fOptions := Value;
        // ������������ ��������� ������ �����
        for oi := Low(TMPSynMemoOption) to High(TMPSynMemoOption) do
            if [oi]*os <> [oi]*Value then begin
                new := oi in Value;
                case oi of
                { ����� ����������� ����� ����� }
                smoShowFileNameInTabSheet,
                smoShowFileNameInFormCaption:
                    if new then fLines.FileName := fLines.FileName;
                { ����� ��������� ������ ������� }
                smoAutoGutterWidth,
                smoVSNET_SectionsStyle:
                    NeedRedrawAll;
                end;
            end;
        // ������������ ���������
        Change([ciOptions]);
    end;
end;


// �������� ���������������� ���������� �� ���������
procedure TMPCustomSyntaxMemo.Change(const ChangedItems: TChangedItems);
begin
    // ���� �������� ������ [], ������������ ����� ���������
    if ChangedItems = [] then
        fChangesSummator := []
    else begin
        // ��������� ���������
        fChangesSummator := fChangesSummator + ChangedItems;
        // ���� ��� ���������� ���������, �������� ���������������� ����������
        // �� ����� ������������ �����������
        if fLines.UpdateCount = 0 then begin
            if Assigned(fOnChange) then
                fOnChange(self, fChangesSummator);
            // ���������� ���������, ����� ��� �� �����������
            fChangesSummator := [];
        end;
    end;
end;


{$IFDEF SYNDEBUG}
// ��� ���������� ��� �������
procedure TMPCustomSyntaxMemo.Log(const LogString: string);
begin
    if LogString = '' then
        fLogDisabled := True
    else
    if fLogDisabled then
        fLogDisabled := False
    else
    if Assigned(fOnLog) then
        fOnLog(self, StringOfChar(' ', Lines.UpdateCount*2) + LogString);
end;

procedure TMPCustomSyntaxMemo.LogFmt(const LogFormat: string; LogArgs: array of const);
begin
    Log(Format(LogFormat, LogArgs));
end;
{$ENDIF}


// �������� ������ ��� ����������� � �����������
procedure TMPCustomSyntaxMemo.NeedRedraw(const Row: Integer);
var Index: Integer;
begin
    if Parent = nil then Exit;
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.NeedRedraw %d', [Row]);
    {} {$ENDIF}
    // ������ �������� ������ � �����������
    if IsLineVisible(Row, @Index) then
        fScreenLines[Index] := True;
    // ������� ������������
    ReDraw;
end;


// �������� � ����������� ��� ������, ���� � ������ ��������
procedure TMPCustomSyntaxMemo.NeedReDrawLE(const Row: Integer);
var Index: Integer;
begin
    if Parent = nil then Exit;
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.NeedRedrawLE %d', [Row]);
    {} {$ENDIF}
    // ������ �������� ������ � �����������
    if IsLineVisible(Row, @Index) then
        while Index <= High(fScreenLines) do begin
            fScreenLines[Index] := True;
            Inc(Index);
        end;
    // ������� ������������
    ReDraw;
end;


// �������� � ����������� ��� ������
procedure TMPCustomSyntaxMemo.NeedRedrawAll;
var i: Integer;
begin
    {} {$IFDEF SYNDEBUG}
    {} Log('Memo.NeedRedrawAll');
    {} {$ENDIF}
    for i := Low(fScreenLines) to High(fScreenLines) do
        fScreenLines[i] := True;
    // ������� ������������
    ReDraw;
end;


// ����������� ������ - �������������� ������ ���������� � ����������� ������
procedure TMPCustomSyntaxMemo.ReDraw;
var i: Integer;
begin
    if (Parent = nil) or (Lines.UpdateCount > 0) then Exit;
    {} {$IFDEF SYNDEBUG}
    {} Log('Memo.Redraw');
    {} {$ENDIF}
    HideCaret;
    for i := Low(fScreenLines) to High(fScreenLines) do
        if fScreenLines[i] then begin
            PaintLineEx3(i, FindVisibleRow(OffsetY, i, False));
            fScreenLines[i] := False;
        end;
    ShowCaret;
end;


// ������������� ����� ���� ������/���� �� ���������
procedure TMPCustomSyntaxMemo.SetDefColor(const Index: Integer; const Value: TColor);
begin
    case Index of
    0: fDefBackColor := Value;
    1: fDefForeColor := Value;
    end;
    Invalidate;
end;



procedure TMPCustomSyntaxMemo.PaintLineEx3(const ScreenRow, Row: Integer);
var Sp: TMPSyntaxParser;
    TextIndent, SelStart, SelEnd: Integer;
    ClipRgn: HRGN;
    R: TRect;
begin
    // ���� ��������� �� ����� - ���� � �������������� ���?
    if not Visible then Exit;

    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.PaintLineEx3 %d as %d', [ScreenRow, Row]);
    {} {$ENDIF}

    // ��������� �������
    PaintGutter(fBuffer.Canvas, Row, ScreenRow);

    // ���� ����� ������ ������������ (������ ����� ������),
    // ������ ��� ������� � �������
    if Lines.IsValidLineIndex(Row) then begin
        // ������� ������
        PaintSectionMarks( fBuffer.Canvas, Row, ScreenRow );
        // �������� ��� ������ ������ (X <= default_offset !!!)
        TextIndent := PixOffsetToWndOffsetEx(0, ScreenRow).X;
        // ������� ��������� ��������������� ������ ��� ���� ���������� ���������
        Sp := TMPSyntaxParser.Create( Lines.Parser[Row] );
        // ���������� ������� ������ (� �����!!)
        Sp.GroupTokens;
        // ������������ ��� �� ������ ���������� � ���������
        if not fRange.IsEmpty()
        and InRange(Row, fRange.StartY, fRange.EndY) then begin
            SelStart := IfThen(Row = fRange.StartY, fRange.StartX, -1);
            SelEnd   := IfThen(Row = fRange.EndY, fRange.EndX, MAXINT);
            Sp.SplitTokens(SelStart, SelEnd);
        end else begin
            SelStart := 0;
            SelEnd := 0;
        end;
        // ������������ � ������������� Clip Region ��� ����� ������
        // �������� ������, ����� �� ����������� ������� ��� OffsetXPix > 0
        with TextRowRect[ScreenRow] do
            ClipRgn := CreateRectRgn(Left, 0, Right, Bottom - Top);
        SelectClipRgn(fBuffer.Canvas.Handle, ClipRgn);
        // ������ ������
        PaintTokens( fBuffer.Canvas, Lines[Row], Sp, TextIndent, SelStart, SelEnd );
        // ���� ������ �������� ������ ������� ��������� ������,
        // ������������� ���� ����������� (��������� ������ ������)
        if fSections.Section[Row].Collapsed then
            PaintDots(fBuffer.Canvas);
        // ���� ������ �������� ���������� ����� - ���������� ���
        if fSelWord.Y = Row then
            with fLines.Parser[Row].Tokens[fSelWord.X] do begin
                R.Left  := TextIndent + CharPosToPixOffset(stStart, Row);
                R.Right := TextIndent + CharPosToPixOffset(stStart + stLength, Row);
                R.Top := 0;
                R.Bottom := fCharHeight - 1;
                fBuffer.Canvas.Brush.Color := clRed;
                fBuffer.Canvas.FrameRect( R );
            end;
        // �������� Clip Region ��� ����� ������
        SelectClipRgn(fBuffer.Canvas.Handle, 0);
        DeleteObject(ClipRgn);
        // ���������� ��������������� ������ �������
        Sp.Free;
    end;
    // ������������ �����
    with EntireRowRect[ScreenRow] do
        BitBlt(Canvas.Handle, 0, Top, Right - Left, Bottom - Top, fBuffer.Canvas.Handle, 0, 0, SRCCOPY)
end;


// ���������� ������� � ������� ������
procedure TMPCustomSyntaxMemo.PaintGutter(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
var RR, GR, R: TRect;
    i: TBookmarkIndex;
begin
    RR := TextRowRect[ScreenRow];
    Dec(RR.Bottom, RR.Top);
    RR.Top := 0;

    GR := EntireGutterRect[ScreenRow];
    Dec(GR.Bottom, GR.Top);
    GR.Top := 0;

    // ����� ������
    with ACanvas do begin
        R := GR;
        Brush.Style := bsSolid;
        Brush.Color := clBtnFace;
        if not (smoVSNET_SectionsStyle in fOptions)
            then Dec(R.Right, 4)
            else Dec(R.Right, fSectionIndent + 4);
        FillRect( R );
        Pen.Color := clBtnHighlight;
        MoveTo(R.Right, R.Top);
        LineTo(R.Right, R.Bottom);
        Inc(R.Right);
        Pen.Color := clBtnShadow;
        MoveTo(R.Right, R.Top);
        LineTo(R.Right, R.Bottom);
        Inc(R.Right);
        Brush.Color := self.Color;
        R.Left := R.Right;
        R.Right := GR.Right;
        FillRect( R );
        FillRect( RR );
        if not Lines.IsValidLineIndex(Row) then Exit;
        // ��������
        if fBookMarks.Find(Row, i) then
            fBookMarks.PaintAt(ACanvas, GR.Left + 2, GR.Top + 2, i);
    end;
end;


// ��������� �������� ������
procedure TMPCustomSyntaxMemo.PaintSectionMarks(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
var SecPnt: TPoint;
    Sec: TMPSynMemoSection;
    MR, RR, GR: TRect;
    i: Integer;
begin
    RR := TextRowRect[ScreenRow];
    Dec(RR.Bottom, RR.Top);
    RR.Top := 0;

    GR := EntireGutterRect[ScreenRow];
    Dec(GR.Bottom, GR.Top);
    GR.Top := 0;

    Sec      := fSections.Section[Row];
    MR       := GetSectionButtonRect(ScreenRow, Sec.Level);
    Dec(MR.Top, EntireRowRect[ScreenRow].Top);
    Dec(MR.Bottom, EntireRowRect[ScreenRow].Top);
    SecPnt   := CenterPoint(MR);

    with ACanvas do begin
        if Sec.RowBeg = Row then begin
            // ������ ������ - ������������� ��������
            if Sec.Collapsed then begin
                Brush.Color := clWhite;
                Pen.Color   := clBlack;
                Rectangle( MR );
            end else begin
                Brush.Color := clBlack;
                FrameRect( MR );
            end;
            Pen.Color := clBlack;
            with MR do begin
                MoveTo(Left + 2, SecPnt.Y);
                LineTo(Right - 2, SecPnt.Y);
                if Sec.Collapsed then begin
                    MoveTo(SecPnt.X, Top + 2);
                    LineTo(SecPnt.X, Bottom - 2);
                end;
                Pen.Color := clDkGray;
                // ����� ������ �� ���������
                MoveTo(Right, SecPnt.Y);
                LineTo(GR.Right - 2, SecPnt.Y);
                if not Sec.Collapsed then begin
                    // ����� ����� ���������
                    MoveTo(SecPnt.X, Bottom);
                    LineTo(SecPnt.X, GR.Bottom);
                end;
            end;
        end else

        // ����� ������ - ������ �����. �������
        if Sec.RowEnd = Row then begin
            Pen.Color := clDkGray;
            MoveTo(SecPnt.X, GR.Top);
            LineTo(SecPnt.X, SecPnt.Y);
            LineTo(GR.Right - 2, SecPnt.Y);
        end else

        // ������ ������, ������������� ��-�������� ������
        if Sec.Level > 0 then begin
            Pen.Color := clDkGray;
            MoveTo(SecPnt.X, GR.Top);
            LineTo(SecPnt.X, GR.Bottom);
        end;

        // ��������� ������������ ����� ������������ ������
        // ������ �� ��� ������ �������� MS VS NET
        if not (smoVSNET_SectionsStyle in fOptions) then
            for i := Sec.Level - 1 downto 1 do begin
                Dec(SecPnt.X, fSectionIndent);
                MoveTo(SecPnt.X, GR.Top);
                LineTo(SecPnt.X, GR.Bottom);
            end;
    end;
end;


// ������������� ���������� ������� ������
procedure TMPCustomSyntaxMemo.PaintDots(const ACanvas: TCanvas);
var R: TRect;
begin
    with ACanvas do begin
        R := ClipRect;
        R.Left := R.Right - 33;
        Brush.Style := bsSolid;
        Brush.Color := self.Color;
        FillRect( R );
        with ClipRect do
            R := Rect(Right - 32, Top + 1, Right - 10, Bottom - 1);
        Brush.Color := clBlue;
        FrameRect( R );
        R := Bounds(R.Left + 5, R.Top + 8, 2, 2);
        FillRect( R );
        OffsetRect(R, 5, 0);
        FillRect( R );
        OffsetRect(R, 5, 0);
        FillRect( R );
    end;
end;


// ������������ ������ � ����������� �� �������� �����
procedure TMPCustomSyntaxMemo.PaintTokens(const ACanvas: TCanvas; s: string; Sp: TMPSyntaxParser; TextIndent, SelStart, SelEnd: Integer);
var wi, CharPos: Integer;
    col: TColor;
    R: TRect;
begin
    with ACanvas do begin
        R := ClipRect;
        // ���������� ����
        Brush.Style := bsSolid;
        for wi := 0 to Sp.Count - 1 do
            with Sp[wi] do begin
                col := fParseAttributes.BackColor[stToken];
                if (col <> clDefault) and not (stsInSelection in stStyle) then begin
                    R.Left := TextIndent + CharPosToPixOffset(stStart, s, Sp);
                    R.Right := TextIndent + CharPosToPixOffset(stStart + stLength, s, Sp);
                    Brush.Color := col;
                    FillRect( R );
                end;
            end;
        // ���������� ���� ���������
        if SelStart <> SelEnd then begin
            R.Left := TextIndent;
            if SelStart > 0 then
                Inc(R.Left, CharPosToPixOffset(fRange.StartX, s, Sp));
            if SelEnd < MAXINT
                then R.Right := TextIndent + CharPosToPixOffset(fRange.EndX, s, Sp)
                else R.Right := ClipRect.Right;
            Brush.Color := fSelColor;
            FillRect( R );
        end;
        // ���������� ���� ���� �� �������
        Brush.Style := bsClear;
        Font.Assign(Self.Font);
        PenPos := Point(TextIndent, 0);
        CharPos := 0;
        for wi := 0 to Sp.Count - 1 do
            with Sp[wi] do begin
                with fParseAttributes.fTokenStyles[stToken] do begin
                    Font.Style := tsStyle;
                    if stsInSelection in stStyle then
                        Font.Color := clBlack
                    else
                    if tsForeground = clDefault then
                        Font.Color := fDefForeColor
                    else
                        Font.Color := tsForeground;
                end;
                R.TopLeft := PenPos;
                Inc(R.Left, (stStart - CharPos) * fCharWidths[False][' ']);
(*                // ����������� ���������� �����
                if (stToken = tokCustomDraw) and Assigned(fOnDrawWord) then
                    R.BottomRight := Point(TextIndent + CharPosToPixOffset(stStart+stLength, s, Sp), fCharHeight);
                    fOnDrawWord(self, ACanvas, R, Row, wi);
                end;    *)
                TextOut(R.Left, R.Top, Copy(s, stStart + 1, stLength));
                CharPos := stStart + stLength;
            end;
    end;
end;



{ TBookmarkManager }

// �����������
constructor TMPBookmarkManager.Create(Owner: TMPCustomSyntaxMemo);
begin
    inherited Create;
    fRichMemo := Owner;
    fImages := TBitmap.Create;
    fImages.LoadFromResourceName(HInstance, 'BOOKMARKS');
    Clear;
end;


// ����������
destructor TMPBookmarkManager.Destroy;
begin
    fImages.Free;
    inherited;
end;


// ���������� ���������� � ���������
procedure TMPBookmarkManager.Clear;
var i: TBookmarkIndex;
begin
    for i := Low(TBookmarkIndex) to High(TBookmarkIndex) do
        fBookMarks[i] := -1;
end;


// ����������
function TMPBookmarkManager.Find(const Row: Integer; var Index: TBookmarkIndex): Boolean;
var i: TBookmarkIndex;
begin
    for i := Low(TBookmarkIndex) to High(TBookmarkIndex) do
        if fBookMarks[i] = Row then begin
            Result := True;
            Index := i;
            Exit;
        end;
    Result := False;
end;


// ���������� ��������
function TMPBookmarkManager.GetBookMarks(const Index: TBookmarkIndex): Integer;
begin
    Result := fBookMarks[Index];
end;


// ������������� ��������
procedure TMPBookmarkManager.SetBookMarks(const Index: TBookmarkIndex; const Row: Integer);
    {}
    procedure SetBookMarkInt;
    var i: TBookmarkIndex;
        n: Integer;
    begin
        // �� ���� ������ ����� ���� ������ ��������..
        if Find(Row, i) then begin
            fBookMarks[i] := -1;
            // ..��� �� �� - � ���� ������ � ������ �������
            if i = Index then
                Exit;
        end;
        // ��� �������� ����� ������������ ������ ��������
        if fBookMarks[Index] >= 0 then begin
            n := fBookMarks[Index];
            fBookMarks[Index] := -1;
            fRichMemo.NeedRedraw(n);
        end;
        // ����� ��������
        fBookMarks[Index] := Row;
    end;
begin
    fRichMemo.fLines.BeginUpdate;
    SetBookMarkInt;
    fRichMemo.NeedRedraw(Row);
    fRichMemo.fLines.EndUpdate;
end;


// ������ ������ �� �������
procedure TMPBookmarkManager.PaintAt(const ACanvas: TCanvas; const x, y: Integer; const Index: TBookmarkIndex);
const BOOKMARK_GLYPH_SIZE = 11;
begin
    BitBlt( ACanvas.Handle,
            x,
            y,
            BOOKMARK_GLYPH_SIZE,
            BOOKMARK_GLYPH_SIZE,
            fImages.Canvas.Handle,
            Index * BOOKMARK_GLYPH_SIZE,
            0,
            SRCCOPY );
end;




initialization

    CF_SYNTAX := RegisterClipboardFormat('MaxPoof Syntax Memo Sections');


end.


