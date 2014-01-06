function GetTrace: boolean;

const
  Count: word = 0;
  feetunits: byte = 0;
  meterunits: byte = 1;
  fathomunits: byte = 2;
type
  EventString = array[0..32] of char;
var
  AntennaEl: single; //Elevation of the GPS antenna measured
                     // in Kinematic mode (meters)
  AntennaHt: single; //Height of the antenna above the water
                     //set by the user (meters)
  BytesPerTrace,itry: integer;
  DataPosition,endtrace: integer;
  Offset: word;
  EventStr: EventString;
  io: word;
  ibyte: byte;
  TraceFound: boolean;
  continue: boolean;

begin { GetTrace }
  GetTrace := false;
  GotTrace := true;
  TraceFound := false;
  continue := true;
  OldPop := Pop;
  {If this is the first trace get the file size}
  if(NumTrace = 0) then InputFileSize := FileSize(f);
  if not Eof(f) then
  begin
   while(not Eof(f) and not TraceFound) do
   begin
     BlockRead(f, Offset, SizeOf(Offset));
     if (Offset > 1000) or (Pop.NumPnts < 0) or (Pop.NumPnts > MAXRAW) then
     begin
      {Error('Bad trace data in file.  Unable to continue');}
      ReportProblemAndQuit('Bad trace data in file. Unable to complete read.');
      if(ProblemForm.QuitProgram) then halt;
      GotTrace := false;
      continue := false;
     end;
     if(continue) then
     begin
       DataPosition := FilePos(f) + Offset;
       inc(Count);
       if Header.Version > $16 then
         BlockRead(f, Pop, Total(PopSize))
       else
         BlockRead(f,Pop,Total(Popsize-8));

       {Test for first trace or past}
       if((Pop.TraceNum >= FirstTrace) and (Pop.TraceNum <= LastTrace)) then
         TraceFound := true;
       endtrace := DataPosition+2*Pop.NumPnts;
       if(not TraceFound) then Seek(f,endtrace);
     end;
   end;
   if(TraceFound) then
   begin
      BlockRead(f, EventStr[0], Total(1));
      BlockRead(f, EventStr[1], Total(ord(EventStr[0])));

      {Check for Unipol}
      if(Pop.khz < 190.0) then UNIPOL := False;
      if(HavePosition) then
      begin
        BlockRead(f, PopLonDeg,SizeOf(PopLonDeg));
        BlockRead(f, PopLatDeg,SizeOf(PopLatDeg));
        if(HaveLatLonXY) then
        begin
          BlockRead(f, PopTransNum,SizeOf(byte));
          BlockRead(f, PopOptions,SizeOf(byte));
          if(PopOptions >= 4) then
          begin
            HaveKinematic := True;
            {ZMode := ELEVZS; let the default remain the Depth for Kinematic}
            {because the editing features do not work in Linematic yet}
          end;
          BlockRead(f, PopOffset,SizeOf(byte));
          BlockRead(f, PopX,SizeOf(PopX));
          BlockRead(f, PopY,SizeOf(PopY));
          BlockRead(f, PopCycles,SizeOf(byte));
          BlockRead(f, PopVolts,SizeOf(byte));
          BlockRead(f, PopPower,SizeOf(byte));
          BlockRead(f, PopGain,SizeOf(byte));
          BlockRead(f, PopPrev,SizeOf(word));
          if HaveKinematic then
          begin
            BlockRead(f, AntennaEl,SizeOf(single));
            BlockRead(f, AntennaHt,SizeOf(single));
            PopElev := AntennaEl-AntennaHt; //Computed elevation of the water surface (meters)
          end;
          BlockRead(f, PopDraft,SizeOf(single));
          BlockRead(f, PopTide,SizeOf(single));
        end;
      end;
      io := ioresult;
      if io = 0 then
      begin
        {Check for last trace}
        endtrace := DataPosition + 2*Pop.NumPnts;
        if(endtrace > InputFileSize) then
        begin
          ReportProblemAndQuit('Bad trace data in file. Unable to complete read.');
          if(ProblemForm.QuitProgram) then halt;
          continue := false;
          GotTrace := false;
          GetTrace := false;
        end;
        {Read tace data}
        if(continue) then
        begin
          Seek(f,DataPosition);
          BlockRead(f, RawPnts, 2*Pop.NumPnts);
          io := ioresult;

          if io <> 0 then
          begin
            ReportProblemAndQuit('Bad trace data in file. Unable to complete read.');
            if(ProblemForm.QuitProgram) then halt;
            GotTrace := false;
            continue := false;
          end;
        end;

        if(continue) then
        begin
          {Check for a new trace in the round robin}
          if NumFreqSet then
          begin
            DisplayTraceID := DisplayTraceID + 1;
            if(DisplayTraceID > NumFreq) then DisplayTraceID := 1;
          end else
          begin
            if NumFreq = 0 then
            begin
              SourceFreq[1] := Pop.kHz;
              NumFreq := 1;
              DisplayTraceID := 1;
              {if the water velocity has not been set by the user,
               set water it from the first trace}
              if(not WaterVelocitySet) then
              begin
                WaterVelocity := Pop.Spdos;
                if Pop.Spdosunits = 0 then WaterVelocity := FT2M*WaterVelocity;
              end;
            end else
            begin
              if not NumFreqSet then
              begin
                if SourceFreq[1] = Pop.kHz then
                begin
                  NumFreqSet := True;
                  DisplayTraceID := 1;
                end
                else
                begin
                  NumFreq := NumFreq + 1;
                  SourceFreq[NumFreq] := Pop.kHz;
                  DisplayTraceID := NumFreq;
                end;
              end;
            end;
          end;
