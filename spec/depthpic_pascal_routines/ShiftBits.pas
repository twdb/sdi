procedure ShiftBits;
{Shift bits in current trace and store in current data block}

var
  MaxValue,MinValue,point,TotalNum,i,i1,i2: integer;
  SumValue, SumAbsValue: real;
  PntValue,trace,StartSample,EndSample,count: integer;
  DataValue: byte;
  RealValue: real;
  dx,dy: double;

begin
  {Fill in with dead traces for missed traces}
  count := 0;
  while ( (Pop.kHz <> SourceFreq[DisplayTraceID]) and
          (count <= NumFreq) and (Numtrace < EstTraceRange) ) do
  begin
   count := count + 1;
   NumTrace := NumTrace + 1;
   {Use a negative TraceStartIndex as a flag for a dead trace}
   TraceStartIndexP^[NumTrace] := -1;
   DisplayTraceID := DisplayTraceID + 1;
   if DisplayTraceID > NumFreq then DisplayTraceID := 1;
  end;
  NumTrace := NumTrace + 1;
  {Compute the index that is SamplesAbove above the bottom}
  StartSample := Pop.DepthPnt - SamplesAbove;
  if StartSample < 1 then StartSample := 1;
  {Compute the index that is SamplesBelow below the bottom}
  EndSample :=  Pop.DepthPnt + SamplesBelow;
  if EndSample > Pop.NumPnts then EndSample := Pop.NumPnts;
  if EndSample > MAXPNT then EndSample := MAXPNT;
  TraceStartIndexP^[NumTrace] := NumData + 1;
  TraceNumberP^[NumTrace] := Pop.TraceNum;
  TraceHourP^[NumTrace] := Pop.Hour;
  TraceMinp^[Numtrace] := Pop.Minute;
  TraceSecP^[NumTrace] := Pop.Second;
  TraceSec100P^[NumTrace] := Pop.Sec100;
  TraceDelayP^[NumTrace] := StartSample - 1;
  TraceNumPntsP^[NumTrace] := EndSample - StartSample + PopOffset + 1;
  TracePicP^[NumTrace,1] := Pop.DepthPnt;
  TraceLonDegP^[NumTrace] := NullPos;
  TraceLatDegP^[NumTrace] := NullPos;
  TraceHeaveP^[NumTrace] := 2.0*Pop.Heave/100.0*SampleRate;
  if(not HaveKinematic) then PopElev := 0.0;
  TraceElevP^[NumTrace] := PopElev; {Record the elevation of the water surface}
  if(NumTrace > 1) then
  begin
   if(PopElev > RefElev) then RefElev := PopElev;
  end else
  begin
   RefElev := PopElev;
  end;
  if(HavePosition) then
  begin
    if(HaveLatLonXY) then
    begin
      TraceLonDegP^[NumTrace] := PopLonDeg; {Store Trace position}
      TraceLatDegP^[NumTrace] := PopLatDeg;
      TraceXP^[NumTrace] := PopX;
      TraceYP^[NumTrace] := PopY;
    end
    else
    begin
      if(abs(PopLatDeg) > 90.0) then
      begin
        PopX := PopLonDeg;
        PopY := PopLatDeg;
        TraceXP^[NumTrace] := PopX;
        TraceYP^[NumTrace] := PopY;
        HaveLatLon := False;
        HaveXY := True;
      end
      else
        begin
          TraceLonDegP^[NumTrace] := PopLonDeg; {Store Trace position}
          TraceLatDegP^[NumTrace] := PopLatDeg;
          HaveLatLon := True;
          HaveXY := False;
        end;
      end;

     {Compute distance along Profile}
     if(HaveXY or HaveLatLonXY) then
     begin
       if(Numtrace > 1) then
       begin
         dx := PopX - TraceXP^[NumTrace-1];
         dy := PopY - TraceYP^[NumTrace-1];
         TraceDistanceP^[NumTrace] :=
           TraceDistanceP^[NumTrace-1] + sqrt(dx*dx+dy*dy);
       end
       else
         TraceDistanceP^[1] := 0.0;
    end;
  end;
  if(header.Version > $16) then
  begin
    MinValue := 32768;
    for point := StartSample to EndSample do
    begin
      if((not UNIPOL) or (header.Version >= 80)) then
      begin
        RealValue := abs(integer(RawPnts[point]) - 32768)/128;
      end
      else begin
        RealValue := RawPnts[point]/257.0;
      end;
      DataValue := byte(round(RealValue));
      NumData := NumData + 1;
      TraceDataP^[NumData] := DataValue;
      if(DataValue < MinValue) then MinValue := DataValue;
    end;
  end;
  if(Header.Version <= $16) then
  begin
    if(PopOffset > 0) then
    begin
      for point := 1 to PopOffset+1 do 
      begin
        NumData := NumData + 1;
        TraceDataP^[Numdata] := 0;
      end;
    end;
    for point := 1 to Pop.NumPnts do
    begin
      PntValue := short(RawPnts[point] shr 4);
      NumData := NumData + 1;
      TraceDataP^[NumData] := byte(round(PntValue/256));
    end;
  end;
end;
