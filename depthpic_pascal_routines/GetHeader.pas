function GetHeader: boolean;
  var
    io: word;
  begin
  GetHeader := true;
  BlockRead(f, Header, SizeOf(Header));
  io := ioresult;
  with Header do
  begin
    if ResolutionCm > 0 then begin
      Pop.Rate := DEFAULTSPDOS * 100 div (ResolutionCm * 2);{25,000 samples/sec}
      Pop.kHz := 200;
    end;
    PopSize := SizeOf(Pop);
    if Version = $13 then
      Dec(PopSize, SizeOf(tNotIn13));
  end;

{Set Flag to read and use position values recording in trace headers}
if(Header.Version >= $30) then  HavePosition := True;

{Set Flag to read both Lat Lon and East and North}
if(Header.Version > 50) then  HaveLatLonXY := True;

  with Header do begin
    if (io <> 0) or (Cr <> 13) or (Lf <> 10) then
    begin
      CloseFile(f);
      GetHeader := False;
      HavePosition := False;
      if(ReportProblemAndQuit('Incorrect or bad file!')) then halt;
    end;
 end;
end;
