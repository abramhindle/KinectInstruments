       	sr = 44100
	kr = 441
	ksmps = 100
	nchnls = 1

      gkindex init 1
      gkmodkn init 1
      gkcar init 1
      gkmod init 1


;zakinit 20,20

;massign 1,1

;turnon 1,0
;maxalloc 1,1


FLcolor	180,200,199
FLpanel 	"FMSynth",200,200
;ibox0  FLbox  "FM Synth (abram)", 1, 6, 12, 300, 20, 0, 0
;FLsetFont   7, ibox0
            
gkcar, gkmod, icarjoy, imodjob FLjoy "C x M", 0, 10, 0, 20, 0, 0, -1, -1, 100,200,0,0
gkscale,    iknob1 FLknob  "Scale", 0.01, 10, -1,1, -1, 30, 100,0
gkmodkn,    iknob2 FLknob  "Modkn", 0.01, 1, 0,1, -1, 30, 130,0
gkindex,    iknob3 FLknob  "Index", 0.01, 1, 0,1, -1, 30, 160,0
gklowp,     iknob4 FLknob  "LPFreq", 20, 20000, -1,1,-1,30,100,40
gkq,        iknob5 FLknob  "LPQ", 1, 1000, -1,1,-1,30,130,40


FLsetVal_i   1.0, iknob1
FLsetVal_i   1.0, iknob2
FLsetVal_i   1.0, iknob3
FLsetVal_i   10000.0, iknob4 ;lowp
FLsetVal_i   1.0, iknob5 ; q
FLsetVal_i   0.0, imodjob

FLsetVal_i   0.0, icarjoy
FLsetVal_i   0.0, imodjob


FLpanel_end	;***** end of container

FLrun		;***** runs the widget thread 


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
        gktime =  100*itime
        gkwin = iwin
        endin
        
        instr 555
ac	oscil	2+gktime/1000, 2+1000*gkwin+40*sin(gktime/100), 1
af      foscili 1000, gkcar + gktime + sin(gktime) + 20 + gkwin, gkwin+1+gktime/1000, gkwin+gkmodkn+gktime/100, gkindex+abs(sin(gktime/1000)), 1        
asig    =   af*ac
        out asig
        endin

        

        instr 666
ac	oscil	1000, 20*gksumc/600+10, 1
al	oscil	1000, 2*20*(1-gksuml/600)+10, 1
ar	oscil	1000, 4*20*gksumr/600+10, 1
af      foscili 1000, 1000*gkscale*gkcar+20*gksumc/600, gkscale*gkmod + 1+gkavg, 3*gkmodkn+gksumr/600, gkindex+gkavgc, 1        
;af      foscili 1000, 20*gksumc/600 + 20, 1+gkavg, 0.7, 0.7 + gkavgc, 1
        ;       ad distort1 af,2,1,0.1,0
;asig    bbcutm     ac+al+ar, 3, 8, 4, 4, 1, 2,0.3, 1
asig    =   af*ac
     al lowpass2 asig,gklowp,gkq
       out asig+al+ar
;	out  af*(ac+al+ar)
        endin
