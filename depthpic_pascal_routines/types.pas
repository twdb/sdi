type

  THeader = record
    Filename: array[1..8] of char;
    Cr, Lf, Version, ResolutionCm: byte;
  end;

  tint10 = short;
  tPop = record    { saved with every pop }
    TraceNum: integer;
    units,            { FEET, METERS, FATHOMS }
    spdosunits: byte; { FEET, METERS }
    Spdos,            { in units }
    minwindow,        { in units/10}
    maxwindow,        { in units/10}
    Draft,            { in units/100 }
    Tide: short;      { in units/100 }
    Heave,            { cm }
    Range: short;     { units/10 }
    DepthRl,          { in meters, all corrections applied }
    MinPntRl,         { index into RawPtr^ word array of window }
    NumPntRl: single; { # of data points - window can start, end at fraction }
    BlankingPnt,      { search for bottom must start after this point }
    DepthPnt,         { index of DepthRl in Raw data array }
    RangePnt,         { search for bottom will not go past this point }
    NumPnts: short;   { # points collected.  > RangePnt }
    Clock: integer;   { 4 byte PC clock tick count since midnight }
    Hour, Minute, Second, Sec100: byte;
    Rate: longint;    { 4 byte A/D samples per second }
    kHz: single;      { actual transmit pulse rate used }
  end;

  tNotIn13 = record
    Rate: longint;    { 4 byte A/D samples per second }
    kHz: single;      { actual transmit pulse rate used }
  end;

  tUse = record
    Units, SpdOsUnits: byte;
    Range, MinWindow, MaxWindow, SpdOs, Draft, Tide, Blanking: tInt10;
  end;
