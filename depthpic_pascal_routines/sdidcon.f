      program sdidcon
c=======================================
c     apply predictive deconvolution to 
c     a sdi subbottom data set
c
c     sdidcon uses subroutine eureka 
c     from "Multichannel Time Series 
c     Analysis with digitial Computer
c     Programs" by Robinson (1967) to
c     solve the normal equations for the
c     prediction filter
c
c     This routine uses FSTAT, FTELL, IARG,
c     GETARG routines from the Absoft unix.lib
c     library
c       John Dunbar
c       Baylor University
c       3-99 
c========================================
      integer*2 rawpnt(16380)
      real t(16380),c(16380),f(10000),a(10000)
      character*1 btrash(100)
    
c     sdi file header data
      character Filename(8)
      integer*1 Cr,Lf,Version,ResolutionCm
      
    
c---sdi trace header data    
c    TraceNum: integer;
c    units,            { FEET, METERS, FATHOMS }
c    spdosunits: byte; { FEET, METERS }
c    Spdos,            { in units }
c    minwindow,        { in units/10}
c    maxwindow,        { in units/10}
c    Draft,            { in units/100 }
c    Tide: short;      { in units/100 }
c    Heave,            { cm }
c    Range: short;     { units/10 }
c    DepthRl,          { in meters, all corrections applied }
c    MinPntRl,         { index into RawPtr^ word array of window }
c    NumPntRl: single; { # of data points - window can start, end at fraction }
c    BlankingPnt,      { search for bottom must start after this point }
c    DepthPnt,         { index of DepthRl in Raw data array }
c    RangePnt,         { search for bottom will not go past this point }
c    NumPnts: short;   { # points collected.  > RangePnt }
c    Clock: integer;   { 4 byte PC clock tick count since midnight }
c    Hour, Minute, Second, Sec100: byte;
c    Rate: longint;    { 4 byte A/D samples per second }
c    kHz: single;      { actual transmit pulse rate used }    
    
      integer*4 TraceNum
      integer*1 units,spdosunits
      integer*2 Spdos,minwindow,maxwindow,Draft,Tide
      integer*2 Heave,Range
      real*4 DepthRl,MinPntRl,NumPntRl
      integer*2 BlankingPnt,DepthPnt,RangePnt,NumPnts
      integer*4 Clock
      integer*1 Hour, Minute, Second, Sec100
      integer*4 Rate
      real*4 kHz
      
      character*1 event(32)
      integer*1 nevent
      integer*2 offset
      character*1024 infile,outfile
      integer*4 FSTAT,FTELL,fsize,fpos,array(13)
      

      external IARC,FSTAT,FTELL
      
c     Get file names from command line, if specified
      numarg = IARGC()
      if(numarg.eq.0) then
        open(unit=1,file='input.bin',form='UNFORMATTED',status='OLD')
        open(unit=2,file='output.bin',form='UNFORMATTED')
      else if(numarg.eq.1) then
        call GETARG(1,infile)
        open(unit=1,file=infile,form='UNFORMATTED',status='OLD')
        open(unit=2,file='output.bin',form='UNFORMATTED')
      else if(numarg.eq.2) then
        call GETARG(1,input)
        call GETARG(2,output)
	infile='c:\subbottom\data\mckinney\5A\sdi\02100805.bin'
	outfile='output.bin'
        open(unit=1,file=infile,form='UNFORMATTED',status='OLD')
        open(unit=2,file=outfile,form='UNFORMATTED')
      else
        write(*,*) 'sdidcon useage:'
        write(*,*) 'sdidcon InputSdifileName OutputFileName'
        write(*,*)
        stop
      end if 
                  
c     check input file size
      itest = FSTAT(1,array)
      fsize = array(8)
      if(itest.eq.1.or.fsize.eq.0) then
        write(*,*) 'sdidcon useage:'
        write(*,*) 'sdidcon InputSdifileName OutputFileName'
        write(*,*)
        stop
      end if 
        
c     read and write the file header
      read(1,end=60) Filename,Cr,Lf,Version,ResolutionCm
      write(2) Filename,Cr,Lf,Version,ResolutionCm 
    
      iversion = Version

c=====start here for each new trace in the data set
      ntrace=0
      write(*,*) 'Traces Completed: '
    
10    continue
c     read offset to start of trace data 
      read(1,end=50) offset
      write(2) offset
      
c     read/write current trace header
      read(1,end=50) TraceNum,units,spdosunits,
     &  Spdos,minwindow,maxwindow,Draft,Tide,Heave,Range,
     &  DepthRl,MinPntRl,NumPntRl,BlankingPnt,DepthPnt,
     &  RangePnt,NumPnts,Clock,Hour,Minute,Second,Sec100,
     &  Rate,kHz
     
      write(2) TraceNum,units,spdosunits,
     &  Spdos,minwindow,maxwindow,Draft,Tide,Heave,Range,
     &  DepthRl,MinPntRl,NumPntRl,BlankingPnt,DepthPnt,
     &  RangePnt,NumPnts,Clock,Hour,Minute,Second,Sec100,
     &  Rate,kHz
     
c     store header values
      nt = NumPnts
      ntw = DepthPnt

      if(ntw.eq.0) ntw = Rate/(kHz*100.0)
      if(ntw.gt.nt) ntw = nt
      ntmtw = nt-ntw
      
c     read/write data trailing the trace header
      read(1,end=50) nevent
      write(2) nevent
      n=nevent
      if(n.gt.0.and.n.le.32) then
        read(1) (event(i),i=1,n)
        write(2) (event(i),i=1,n)
      else if(n.lt.0.or.n.gt.32) then    
         write(*,*) 'Invalid SDI data format -> could not process'
         stop     
      end if

c     test for bad data
      if(NumPnts.le.0) then
         write(*,*) 'Invalid SDI data format -> could not process'
         stop
      end if
      
c     read to the start of the data
      moreoff = offset-56-n-1
      if(moreoff.gt.0) then
        read(1) (btrash(i),i=1,moreoff)
        write(2) (btrash(i),i=1,moreoff)
      end if
      
c     read the current trace
      read(1,end=50) (rawpnt(i),i=1,NumPnts)
      
c     convert raw data into reals
      do 20 i=1,NumPnts
         t(i) = float(rawpnt(i) - 32768)
 20   continue
 
c     for now by pass lower frequency traces and only decon the 200 kHz traces
c      if(kHz.lt.199.0) go to 40
      
c     compute the autocorrelation function of the trace
c     starting at the water bottom
      call cross(ntmtw,t(ntw),ntmtw,t(ntw),ntmtw,c)

c     set the prediction distance to 10 cycles of the
c     primary source frequency
      alpha = Rate/(kHz*100.0)

c     prewhiten autocorrelation of trace
      c(1) = 1.01*c(1)

c     solve normal equations for filter coef that predict the multiples
c      nf = 3*ntw + alpha
      nf = 3*alpha
      if(nf.gt.nt) nf = nt
      call eureka(nf,c,c(alpha+1),f,a)

c     compute the prediction error filter
      na = nf + alpha
      call preop(nf,f,na,a,alpha)

c     apply the filter to the entire trace 
      call fold(na,a,nt,t,nc,c)

c     convert the trace values back into raw points
      do 30 i=1,nt
        rawpnt(i) = c(i)+32768
  30  continue
  
c     count the traces processed
      icount = icount + 1
  
c     write the processed trace
  40  continue
      write(2) (rawpnt(i),i=1,nt)
      
      j= icount/1000
      if(j*1000.eq.icount) then
         fpos = FTELL(1)
         idone = fpos/fsize*100.0
         write(*,*) icount,' Traces Processed ',idone,'%',' Done'
      end if
      
c=====go get a new trace
	ntrace=ntrace+1
	write(*,*) ntrace
      go to 10
      
c=====come here when the end-of-file is reached
  50  continue
  
      write(*,*) icount,' Total Traces Processed'
      stop
  
  60  continue
      write(*,*) 'Empty input file -> no process performed' 
        
      stop
      end
