       	sr = 22050
	kr = 220.5
	ksmps = 100
	nchnls = 1


      gksum  init 0
      gkavg  init 0
      gksumc init 0
      gkavgc init 0
      gksumr init 0
      gkavgr init 0
      gksuml init 0
      gkavgl init 0
      gktime init 0
      gkwin init 0

        instr 1
        p3 = 1/44100
      isum = p4
      iavg = p5
      isumc = p6
      iavgc = p7
      isuml = p8
      iavgl = p9
      isumr = p10
      iavgr = p11
      ishare = 0.2
      ires = 1 - ishare
      gksum  = gksum*ires + isum*ishare
      gkavg  = gkavg*ires + iavg*ishare
      gksumc = gksumc*ires + isumc*ishare
      gkavgc = gkavgc*ires + iavgc*ishare
      gksumr = gksumr*ires + isumr*ishare
      gkavgr = gkavgr*ires + iavgr*ishare
      gksuml = gksuml*ires + isuml*ishare
      gkavgl = gkavgl*ires + iavgl*ishare 
        endin   

        instr 3
        p3=1/44100
        gksumr = 440
        endin


        instr 2
        p3 = 1/44100
        itime = p4
        iwin = p5
        gktime = 10000 - 100*itime
        gkwin = iwin
        endin
        
        instr 555
ac	oscil	2+gktime/1000, 2+1000*gkwin+40*sin(gktime/100), 1
af      foscili 1000, gktime + sin(gktime) + 20 + gkwin, gkwin+1+gktime/1000, gkwin+1+gktime/100, 0.3+abs(sin(gktime/1000)), 1        
asig    =   af*ac
        out asig
        endin

        

        instr 666
ac	oscil	1000, 20*gksumc/600+10, 1
al	oscil	1000, 2*20*(1-gksuml/600)+10, 1
ar	oscil	1000, 4*20*gksumr/600+10, 1
af      foscili 1000, 20*gksumc/600 + 20, 1+gkavg, 2.8-gksumr/600, 0.3+gkavgc, 1        
;af      foscili 1000, 20*gksumc/600 + 20, 1+gkavg, 0.7, 0.7 + gkavgc, 1
        ;       ad distort1 af,2,1,0.1,0
;asig    bbcutm     ac+al+ar, 3, 8, 4, 4, 1, 2,0.3, 1
asig    =   af*ac
;     al lowpass2 asig,40,20
       out asig+al+ar
;	out  af*(ac+al+ar)
        endin
