
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
            
gkscale,    iknob1 FLknob  "Scale", 0.01, 2, -1,1, -1, 30, 100,0
gkmodkn,    iknob2 FLknob  "Modkn", 0.01, 1, 0,1, -1, 30, 130,0
gkindex,    iknob3 FLknob  "Index", 0.01, 1, 0,1, -1, 30, 160,0
gkfreq,    iknob4 FLknob  "Freq", 0.01, 1000, 0,1, -1, 30, 0,0
gkq,    iknob5 FLknob  "Q", 0.01, 1000, 0,1, -1, 30, 40,0



FLsetVal_i   1.0, iknob1
FLsetVal_i   1.0, iknob2
FLsetVal_i   1.0, iknob3
FLsetVal_i   1000, iknob4
FLsetVal_i   1000, iknob5
;FLsetVal_i   0.0, icarjoy
;FLsetVal_i   0.0, imodjob


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
      gky init 0
      gkx init 0

        instr 1
        p3 = 1/44100
        ix = p4
        iy = p5 
        ic = p6 
        gkx = ix
        gky = iy
        gkc = ic
        endin   

        instr 555
af1      foscili 2000, (320-abs(gkx-320))*gkscale, gkc+2*gky/480, 5*gkmodkn, 5*gkindex, 1        
af2      foscili 2000, 0.98*(320-abs(gkx-320))*gkscale, gkc+2*gky/480, 5*gkmodkn, 5*gkindex, 1        
af3      foscili 2000, 1.04*(320-abs(gkx-320))*gkscale, gkc+2*gky/480, 5*gkmodkn, 5*gkindex, 1        
ar       lowpass2 af1+af2+af3, gkfreq, gkq
           out ar
        endin

