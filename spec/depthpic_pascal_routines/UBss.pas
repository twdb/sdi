unit UBss;

interface

uses
  Windows, SysUtils, Classes, sdCoord;

const
  FEET = 0;
  METERS = 1;
  FATHOMS = 2;

type
  THeader = packed record
    Filename: packed array[0..7] of Char;
    Cr, Lf, Version, ResCm: Byte;
  end;
  TInt10 = SmallInt;
  TInt100 = SmallInt;
  TRecCfg = packed record { saved in config file and with every pop }
    TraceNum: longint;
    Units,            { FEET, METERS, FATHOMS }
    Spdosunits: byte; { FEET, METERS }
    Spdos: SmallInt;  { in units }
    Minwindow,        { in units/10}
    Maxwindow: TInt10;{ in units/10}
    Draft,            { in units/100 }
    Tide: TInt100;    { in units/100 }
  end;
  TPop = packed record    { saved with every pop }
    Heave: SmallInt;  { cm }
    Range: TInt10;    { units/10, really max depth displayable(Xd range+draft) }
    DepthRl,          { in meters below mean water level. <= ver 4.1 was below geoid }
    MinPntRl,         { index into RawPtr^ word array of window top }
    NumPntRl: single; { # of data points in window - can start, end at fraction
                        Was set using axis height for mid 3.2 and earlier - bad if offset > 10 units }
                      { All Pnts measured from start of data, w/o offset }
    BlankingPnt,      { search for bottom must start after this data point }
    DepthPnt,         { index of DepthRl in Raw data array }
    RangePnt,         { of Range. Search for bottom will not go past this point }
    NumPnts: SmallInt;{ # points collected.  RangePnt + 2 m ( 1 m after ver 3.1? }
    Clock: longint;   { 4 byte PC clock tick count since midnight }
    Hour, Minute, Second, Sec100: byte; { conversion of above Clock field }
    Rate: longint;    { 4 byte A/D samples per second }
    kHz: single;      { actual transmit pulse rate used }
  end;
  TEventStr = String[31];
  { new with 3.0 }
  TPopExtra = packed record
    LatLon: TLLCoord;

    { next 3 are new with 3.1 }
    Transducer: byte; { 1..5 in order of frequency (bottom to sub-bottom)}
    Options: byte;    { 1=Bipolar, 2=XY in LatLon, 4=Rtk mode }
    DataOffset: byte;

    { new with 3.3 }
    XY: TXYCoord;

    { new with 4.0 }
    Cycles,
    Volts,            { 0=10, 1=5, 2=2.5, 3=1.25 }
    Power,
    Gain: Byte;
    PrevOffset: Word;

    { new with 4.2 }
    AntennaEl, AntennaHt, Draft, Tide: Single;  { meters }

    { new with 4.3 }
    GpsMode: ShortInt;
    HDop: Single;
  end;
  TBssString = array[0..31] of Char;
  TBssHeader = record
    FileDescriptor,
    Filename: TBssString;
    FileVersion,
    SoftwareVersion,
    HardwareVersion: Word;
    Year: Word;
    Month,
    Day: Byte;
    TimeOfDay: TDateTime;{ fraction of a day since midnight }
    FileNumber: SmallInt;
    DisplayUnits,      { FEET, METERS, FATHOMS }
    DisplaySpdosUnits: Byte; { FEET, METERS }
    Comment,
    Reserved: TBssString;
  end;
  TBssRec = record
    TraceNum: LongInt;
    Year: Word;
    Month,
    Day: Byte;
    TimeOfDay: TDateTime;{ fraction of a day since midnight }
    NumPoints: LongInt;{ # points collected.  XdRange + 1 m ( 2 m before ver 3.2 }
    Spdos,             { m/sec }
    Rate: Double;      { A/D samples per second }
    Transducer: Byte;  { 1..5 in order of frequency (bottom to sub-bottom)}
    HasRtk,
    BiPolar,
    HasUndulation: ByteBool;
    GpsMode: Shortint;
    kHz,               { actual transmit pulse rate used }
    Undulation,        { m }
    Draft,             { m }
    Tide,              { m user entered mean water level above geoid }
    RtkTide,           { m measured above geoid or Tide + Heave }
    Elevation,         { m of Depth[0] above geoid }
    Heave,             { m If this is zero, any heave present should have been subtracted from Draft }
    AntennaHt,         { m above water }
    AntennaEl,         { m above geoid }
    Keel,              { m below water }
    Blanking,          { search for bottom must start after this distance from Xducer }
    WindowMin,         { for WindowMin, WindowMax, Range and Depth: array index = }
    WindowMax,         { 2 Rate(X - Draft + Heave)/Spdos }
    XdRange: Single;   { max depth 'displayable' is XdRange + Draft - Heave}
    Depth: array[0..4] of Single; { in meters below mean water level. <= ver 4.1 was below geoid }
    LatLon: TLLCoord;
    XY: TXYCoord;
    HDop: Single;
    Cycles,
    Volts,
    Power,
    Gain: Byte;
    Comment: TBssString;
  end;
//  EBssError = class(Exception);
  TBss = class(TObject)
  private
    FFileOpen: Boolean;
    PrevNumPnts: SmallInt;
    FFileName: String;
    Header: THeader;
    RecCfg: TRecCfg;
    Pop: TPop;
    PopExtra: TPopExtra;
    PopSize,
    PopExtraSize: Integer;
    EventStr: TEventStr;
    FDataPtr: PWord;
    procedure InitBssHeader;
    procedure InitBssRec;
    procedure RaiseBssError(const Task, Msg: String);
    procedure RaiseTraceError;
    { Private declarations }
  public
    Head: TBssHeader;
    Rec: TBssRec;
    procedure CloseBss;
    function EofBss: Boolean;
    property Filename: String read FFilename;
    property FileOpen: Boolean read FFileOpen;
    function FilePosBss: Int64;
    function GpsStr: String;
    procedure ResetBss(const Filename: TFilename);
    procedure ReadBss(out DataPtr: PWord);
    function Volts: Single;
    constructor Create; virtual;
    destructor Destroy; override;
    { Public declarations }
  end;
  TadVolt = (adB10, adB5, adB2pt5, adB1pt25);
  TUserUnits = record
    UnitsPerBasis: double;
    Abrev: string[5];
  end;

const
  UUnits: array[FEET..FATHOMS] of TUserUnits = (
        (UnitsPerBasis: 1/0.3048;     Abrev: 'ft'),
        (UnitsPerBasis: 1;            Abrev: 'm'),
        (UnitsPerBasis: 1/(0.3048*6); Abrev: 'fm'));
  USpdUnits: array[FEET..METERS] of string[7] = ('ft/sec', 'm/sec');
  AdVoltage: array[adB10..adB1pt25] of Single = (10.0, 5.0, 2.5, 1.25);

var
  BssF: file of Byte;
  Bss: TBss;

implementation

uses
  Nmea,
  Math;

constructor TBss.Create;
begin
  inherited;
  FDataPtr := nil;
  FFileOpen := False;
  FFilename := '';
end;

destructor TBss.Destroy;
begin
  CloseBss;
  ReallocMem(FDataPtr, 0);
  inherited;
end;

procedure TBss.InitBssHeader;
const
  UNKNOWNGPS = -2;
var
  Bip: Boolean;
  FnPChar: PChar;
  FBssHeader: TBssHeader;

  function ScanDate: Integer;
  var
    Dest: array[0..3] of Char;
  begin
    result := StrToIntDef(StrLCopy(Dest, FnPChar, 2), -1);
    Inc(FnPChar, 2);
  end;

  function Char36ToInt(C: Char): Integer;
  const
    T36: String = '0123456789abcdefghijklmnopqrstuvwxyz';
  begin
    result := Pos(LowerCase(C), T36) - 1;
  end;

begin { InitBssHeader }
  ZeroMemory(Addr(FBssHeader), SizeOf(FBssHeader));
  if (Header.CR <> 13) or (Header.LF <> 10) then
    raise Exception.Create('header');
  FBssHeader.FileDescriptor := 'BSS Specialty Devices, Inc.';
  StrLCopy(FBssHeader.Filename, Header.Filename, SizeOf(Header.Filename));
  FBssHeader.Filename[9] := #0;
  FnPChar := FBssHeader.Filename;
  FBssHeader.Year := ScanDate;
  if FBssHeader.Year < 90 then
    Inc(FBssHeader.Year, 2000)
  else if FBssHeader.Year < 100 then
    Inc(FBssHeader.Year, 1900);
  FBssHeader.Month := ScanDate;
  FBssHeader.Day := ScanDate;
  FBssHeader.FileNumber := ScanDate;
  if FBssHeader.FileNumber < 0 then begin
    FBssHeader.FileNumber := Char36ToInt(FBssHeader.Filename[6]) * 36 +
      Char36ToInt(FBssHeader.Filename[7]) - 234;
  end;
  FBssHeader.TimeOfDay := 0.0; //so first InitBssRec won't increment the day
  FBssHeader.SoftwareVersion := MakeWord(Header.Version and $0F, Header.Version shr 4);
  PopSize := SizeOf(TPop);
  Bip := True;
  if Header.Version <= $16 then begin
    Bip := False;
    Dec(PopSize, 8);
    if Header.ResCm > 0 then
      Pop.Rate := Round(75000 / Header.ResCm)
    else
      Pop.Rate := 25000;
    Pop.kHz := 200.0;
  end;
  if Header.Version >= $43 then
    PopExtraSize := 2 * SizeOf(TXYCoord) + 5 * Sizeof(Single) + 10
  else if Header.Version >= $42 then
    PopExtraSize := 2 * SizeOf(TXYCoord) + 4 * Sizeof(Single) + 9
  else if Header.Version >= $40 then
    PopExtraSize := 2 * SizeOf(TXYCoord) + 9
  else if Header.Version >= $33 then
    PopExtraSize := 2 * SizeOf(TXYCoord) + 3
  else if Header.Version >= $31 then
    PopExtraSize := SizeOf(TXYCoord) + 3
  else if Header.Version >= $30 then
    PopExtraSize := SizeOf(TXYCoord)
  else
    PopExtraSize := 0;
  with PopExtra do begin
    LatLon.Latitude := 100.0;
    Options := Byte(Bip);
    DataOffset := 0;
    XY := NULLXY;
    Cycles := 0;
    Volts := $FF;
    Power := $FF;
    Gain := $FF;
    AntennaEl := 0.0;
    AntennaHt := 0.0;
    Draft := 0.0;
    Tide := 0.0;
    GpsMode := UNKNOWNGPS;
    HDop := -1;
  end;
  Head := FBssHeader;
end;

procedure TBss.InitBssRec;
const
  MAXTRAN = 5;
  TranKhz: array[1..MAXTRAN] of Single = (200.0, 50.0, 24.0, 12.0, 3.5);
var
  Delta, Temp: Single;
  T: Integer;
  Y, M, D: Word;
  FBssRec: TBssRec;

  function ToInternal(User: Double): Double;
  begin
    result := User / UUnits[RecCfg.Units].UnitsPerBasis;
  end;

  function Int100ToInternal(Int100: TInt100): Single;
  begin
    result := ToInternal(Int100) * 0.01;
  end;

  function Int10ToInternal(Int10: TInt10): Single;
  begin
    result := ToInternal(Int10) * 0.1;
  end;

  function PntToSource(Pnt: SmallInt): Double;
  begin
    Result := (Pnt + PopExtra.DataOffset) * FBssRec.SpdOs * 0.5 / FBssRec.Rate;
  end;

begin { InitBssRec }
  ZeroMemory(Addr(FBssRec), SizeOf(FBssRec));
  FBssRec.TraceNum := RecCfg.TraceNum;
  with Pop do
    FBssRec.TimeOfDay := EncodeTime(Hour, Minute, Second, Sec100 * 10);
  if FBssRec.TimeOfDay < Head.TimeOfDay then begin
    with Head do
      DecodeDate(EncodeDate(Year, Month, Day) + 1.0, Y, M, D);
    FBssRec.Year := Y;
    FBssRec.Month := M;
    FBssRec.Day := D;
  end
  else begin
    FBssRec.Year := Head.Year;
    FBssRec.Month := Head.Month;
    FBssRec.Day := Head.Day;
  end;
  FBssRec.Spdos := RecCfg.Spdos / UUnits[RecCfg.Spdosunits].UnitsPerBasis;
  FBssRec.Rate := Pop.Rate;
  FBssRec.BiPolar := Odd(PopExtra.Options);
  FBssRec.HasRtk := (PopExtra.Options and 4) <> 0;
  FBssRec.HasUndulation := False;
  FBssRec.NumPoints := Pop.NumPnts - PopExtra.DataOffset;
  FBssRec.kHz := Pop.kHz;
  if Header.Version <= $41 then begin
    PopExtra.Draft := Int100ToInternal(RecCfg.Draft);
    PopExtra.Tide := Int100ToInternal(RecCfg.Tide);
    if (Header.Version < $33) then begin
      if (PopExtra.Options and 2) <> 0 then begin
        PopExtra.XY := TXYCoord(PopExtra.LatLon);
        PopExtra.LatLon := LLCoord(100, 200);
      end;
      if Header.Version < $31 then begin
        PopExtra.Transducer := 1;
        Delta := MAXSINGLE;
        for T := 1 to MAXTRAN do begin
          Temp := Abs(Pop.kHz - TranKhz[T]);
          if Temp < Delta then begin
            PopExtra.Transducer := T;
            Delta := Temp;
          end;
        end;
      end;
    end;
  end;
  FBssRec.Transducer := PopExtra.Transducer;
  FBssRec.LatLon := PopExtra.LatLon;
  FBssRec.XY := PopExtra.XY;
  FBssRec.AntennaHt := PopExtra.AntennaHt;
  FBssRec.AntennaEl := PopExtra.AntennaEl;
  FBssRec.Draft := PopExtra.Draft;
  FBssRec.Tide := PopExtra.Tide;
  FBssRec.Heave := Pop.Heave * 0.01;
  if FBssRec.HasRtk then
    FBssRec.RtkTide := FBssRec.AntennaEl - FBssRec.AntennaHt
  else
    FBssRec.RtkTide := FBssRec.Tide + FBssRec.Heave;
  FBssRec.Elevation := FBssRec.RtkTide - Pop.DepthRl;
  FBssRec.Undulation := 0.0;
  FBssRec.WindowMin := Int10ToInternal(RecCfg.Minwindow);
  FBssRec.WindowMax := Int10ToInternal(RecCfg.Maxwindow);
  FBssRec.XdRange := Int10ToInternal(Pop.Range);
  FBssRec.Cycles := PopExtra.Cycles;
  FBssRec.Volts := PopExtra.Volts;
  FBssRec.Power := PopExtra.Power;
  FBssRec.Gain := PopExtra.Gain;
  FBssRec.HDop := PopExtra.HDop;
  FBssRec.GpsMode := PopExtra.GpsMode;
  FBssRec.Keel := 0.0;
  FBssRec.Blanking := PntToSource(Pop.BlankingPnt);
  FBssRec.Depth[0] := Pop.DepthRl;
  StrPLCopy(FBssRec.Comment, EventStr, SizeOf(FBssRec.Comment) - 1);
  if (RecCfg.Units > FATHOMS) or (RecCfg.SpdOs < 100) or (PopExtra.DataOffset > 20) then
    RaiseTraceError
  else
    Rec := FBssRec;
end;

procedure TBss.ResetBss(const Filename: TFilename);
var
  Fp: Integer;
  PD: PWord;
begin
  FFilename := Filename;
  PrevNumPnts := 0;
  Fp := 0;
  try
    CloseBss;
    AssignFile(BssF, Filename);
    FileMode := fmOpenRead; { allows reading from a CD }
    try
      Reset(BssF);
      FFileOpen := True;
      BlockRead(BssF, Header, SizeOf(THeader));
      Fp := FilePos(BssF);
      InitBssHeader;
    finally
      FileMode := fmOpenReadWrite; { must change back for other resets }
    end;
  except
    on E: Exception do
      RaiseBssError('opening', E.Message);
  end;
  ReadBss(PD);
  Seek(BssF, Fp);
  Head.TimeOfDay := Rec.TimeOfDay;
  Head.DisplayUnits := RecCfg.Units;
  Head.DisplaySpdosUnits := RecCfg.Spdosunits;
end;

procedure TBss.ReadBss(out DataPtr: PWord);
var
  Count: Integer;
  Offset: Word;
  DataPos: LongInt;
  Dp: PWord;
begin
  try
    BlockRead(BssF, Offset, SizeOf(Offset));
    DataPos := FilePos(BssF) + Offset;
    BlockRead(BssF, RecCfg, SizeOf(TRecCfg));
    BlockRead(BssF, Pop, PopSize);
    BlockRead(BssF, EventStr, 1);
    if Length(EventStr) >= SizeOf(EventStr) then
      RaiseTraceError
    else begin
      BlockRead(BssF, EventStr[1], Length(EventStr));
      BlockRead(BssF, PopExtra, PopExtraSize);  { New with version 3.0 }
      Seek(BssF, DataPos); { for forward compatibility.  Does nothing if version up to date }
      if Pop.NumPnts <> PrevNumPnts then begin
        ReallocMem(FDataPtr, Pop.NumPnts * 2);
        PrevNumPnts := Pop.NumPnts;
      end;
      DataPtr := FDataPtr;
      BlockRead(BssF, FDataPtr^, Pop.NumPnts * 2);
      InitBssRec;
      Inc(DataPtr, PopExtra.DataOffset);
      Dp := DataPtr;
      if Rec.BiPolar then //was in Offset Binary
        for Count := 1 to Rec.NumPoints do begin
          Dp^ := Dp^ xor $8000;
          Inc(Dp);
        end
      else                //lose 1 bit to go to signed
        for Count := 1 to Rec.NumPoints do begin
          Dp^ := Dp^ shr 1;
          Inc(Dp);
        end;
    end;
  except
    on E: Exception do
      RaiseBssError('reading', E.Message);
  end;
end;

procedure TBss.CloseBss;
begin
  if FFileOpen then begin
    CloseFile(BssF);
    FFileOpen := False;
  end;
end;

function TBss.EofBss: Boolean;
begin
  result := not FFileOpen or Eof(BssF);
end;

function TBss.FilePosBss: Int64;
begin
  if FFileOpen then
    result := FilePos(BssF)
  else
    result := 0;
end;

function TBss.GpsStr: String;
begin
  result := GetGpsQualityStr(Rec.GpsMode);
end;

procedure TBss.RaiseBssError(const Task, Msg: String);
begin
  raise Exception.CreateFmt('Error %s %s %s', [Task, ExtractFilename(FFilename), Msg]);
end;

procedure TBss.RaiseTraceError;
begin
  raise Exception.CreateFmt('trace %d', [RecCfg.TraceNum])
end;

function TBss.Volts: Single;
begin
  if Rec.Volts > Byte(adB1pt25) then
    result := 0.0
  else
    result := adVoltage[TadVolt(Rec.Volts)];
end;

end.
