sr=44100
kr=441

gkgbegamp init 1000
gkgbegcps init 260
gkgbegmod init 2
gkgbegdist1 init 2
gkgbegdist1 init 2

FLcolor	180,200,199
FLpanel 	"GBEB",200,100
gkgbegamp,    iknobamp    FLknob  "Amp", 10  , 2000, -1,1, -1,  40, 0,0
gkgbegcps,    iknobcps    FLknob  "CPS",   10  , 1700, -1,1, -1,  40, 50,0
gkgbegmod,    iknobpluck  FLknob  "Plucks",  0.1  , 8, 0,1, -1, 40, 100,0
gkgbegdist1,    iknobdist1  FLknob  "PreGain",  0.1  , 10, 0,1, -1, 40, 0,50
gkgbegdist2,    iknobdist2  FLknob  "PostGain",  0.1  , 10, 0,1, -1, 40, 50,50

FLsetVal_i   2.0, iknobpluck
FLsetVal_i   1000, iknobamp
FLsetVal_i   260, iknobcps
FLsetVal_i   6, iknobdist1
FLsetVal_i   4, iknobdist2

FLpanel_end	;***** end of container

FLrun		;***** runs the widget thread 


        instr Harmonic
        ilen   = p3
        iamp   = p4/(1+1/2+1/3+1/4+1/5+1/6+1/7+1/8)
        istart = p5
        itab   = (p6 > 0)?p6:1
        iconstant = 1
        iampconst = 10
;            attack     decay      sustain, release
aenvr   adsr 1*ilen/10, 6*ilen/10, 0.8, 3*ilen/10
kvib    oscil 6,istart*50,1
;kvib    = 0
a0	oscil	iamp * 1/1, 1 * istart + iconstant*kvib, itab
a1	oscil	iamp * 1/2, 2 * istart + iconstant*kvib, itab
a2	oscil	iamp * 1/3, 3 * istart + iconstant*kvib, itab
a3	oscil	iamp * 1/4, 4 * istart + iconstant*kvib, itab
a4	oscil	iamp * 1/5, 5 * istart + iconstant*kvib, itab
a5	oscil	iamp * 1/6, 6 * istart + iconstant*kvib, itab
a6	oscil	iamp * 1/7, 7 * istart + iconstant*kvib, itab
a7	oscil	iamp * 1/8, 8 * istart + iconstant*kvib, itab
        asig = (a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7)
        out asig*aenvr
;        out     iamp/(1+1/2+1/3+1/4+1/5+1/6+1/7+1/8) * (a0 * a1 * a2 * a3 * a4 * a5 * a6 * a7)
	endin

        instr Pluck
a1 		pluck 	2000, p4, p5, 4, 1
		out 	a1
		endin

        instr ContPlucker
        itab = 1
        istart = p5
        iamp = p4
adump  delayr 0.01+1/p5      ; we ignore this value
        kcps = p5
adelay deltapi 1/kcps
arand  rand 1
alp    resonr adelay, kcps, 20
;alp     streson adelay, kcps, 0.96
asum    = arand + alp
asum    clip asum,0,100
       delayw asum
       out asum*iamp
       endin


; doesn't sound that bad..
; 
        instr DT
        itab = 1
        iamp = p4
        icps = p5
;kenv    adsr 0.1*p3, 0.1*p3, 0.3, 0.9*p3
adelay init 0
arand  rand 1
alp    resonr adelay, icps, 20
asum    = (arand + 0.01*alp)
asum    clip asum, 0, 5
adelay   delay asum, 1/icps
       out asum*iamp
       endin


;i"DT3" 0 3  1000 10
;i"DT3" 10 3 1000 20
;i"DT3" 15 3 1000 30
;i"DT3" 20 3 1000 40
;i"DT3" 25 3 1000 50
;
        instr DT3
        itab = 1
        iamp = p4
        icps = p5
adelay1 init 0
adelay2 init 0
adelay3 init 0
arand1  rand 1
arand2  rand 1
arand3  rand 1
alp1    resonr adelay1, icps, 20
alp2    resonr adelay2, 2*icps, 20
alp3    resonr adelay3, 3*icps, 20
asum1   clip arand1 + 0.1*alp1 , 0 , 5
asum2   clip arand2 + 0.1*alp2 , 0 , 5
asum3   clip arand3 + 0.1*alp3 , 0 , 5
adelay1   delay asum1, 1/icps
adelay2   delay asum2, 1/(2*icps)
adelay3   delay asum3, 1/(3*icps)
       out (asum1 + asum2 + asum3)*iamp
       endin


        instr DTHarm
        itab = 1
        iamp = p4
        icps = p5
kenv    adsr 0.3*p3, 0.1*p3, 0.5, 0.5*p3
adelay0 init 0
adelay1 init 0
adelay2 init 0
adelay3 init 0
arand0  rand 1
arand1  rand 1
arand2  rand 1
arand3  rand 1
alp0    resonr adelay0, icps, 20
alp1    resonr adelay1, 2*icps, 2*20
alp2    resonr adelay2, 3*icps, 3*20
alp3    resonr adelay3, 4*icps, 4*20
asum    = kenv*(arand0 + 0.3*alp0 + arand1 + arand2 +arand3 + 0.3*(alp0 + alp1 + alp2 + alp3))/(1.0 + 1/2 + 1/3 + 1/4)
asum    clip asum, 0, 5
adelay0   delay asum, 1/(1*icps)
adelay1   delay asum, 1/(2*icps)
adelay2   delay asum, 1/(3*icps)
adelay3   delay asum, 1/(4*icps)
       out asum*iamp
       endin


; i"GB" 0  3 1000 30 5
; i"GB" 3  3 1000 40 5
; i"GB" 6  3 1000 50 5
; i"GB" 9  3 1000 60 5
; 
; i"GB" 12  3 1000 30 1
; i"GB" 15  3 1000 40 1
; i"GB" 18  3 1000 50 1
; i"GB" 21  3 1000 60 1
; 
; i"GB" 12  3 1000 30 2
; i"GB" 15  3 1000 40 2
; i"GB" 18  3 1000 50 2
; i"GB" 21  3 1000 60 2
; 
; i"GB" 24  3 1000 30 3
; i"GB" +  3 1000 40 3
; i"GB" +  3 1000 50 3
; i"GB" +  3 1000 60 3
; 
; i"GB" +  3 1000 30 4
; i"GB" +  3 1000 40 4
; i"GB" +  3 1000 50 4
; i"GB" +  3 1000 60 4
; 
; this instrument is a harmonic guitar pluckerish instrument
; sorta short
; more like a horn
       instr GB
       iamp = p4
       icps = p5
       itab = (p6>0)?p6:1
amod	oscili	1, 4, 5
kres    line 0, p3, 1
;kres    oscili 1,0.5,5
kcps = icps + kres
amod	oscili	1, 1.25+kres, 5

a0	oscil	iamp , 1 * kcps, itab
a1	oscil	iamp , 2 * kcps, itab
a2	oscil	iamp , 3 * kcps, itab
a3	oscil	iamp , 4 * kcps, itab
a4	oscil	iamp , 5 * kcps, itab
a5	oscil	iamp , 6 * kcps, itab
a6	oscil	iamp , 7 * kcps, itab
a7	oscil	iamp , 8 * kcps, itab
        asig = (a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7) / 8
acomb         comb asig,  0.1, 1/icps
acomb1        comb asig, 0.1, 1/(2*icps)
acomb2        comb asig, 0.1, 1/(3*icps)
;ar       tone 3*(acomb+acomb1+acomb2), 1000
ar      streson acomb+acomb1+acomb2, icps, 0.96
        out ar*amod
        endin
        


; violin strike at 1280
       instr GBNoise
       idur = p3
       iamp = p4
       icps = p5
       itab = (p6>0)?p6:1
       imod = (p7>0)?p7:2
aenv    adsr 0.01*idur,0.1*idur,0.9,0.1*idur
kres    = 0 ;line 0, p3, 1
;kres    oscili 1,0.5,
kcps = icps + kres
amod	oscili	1, imod, itab
;adump   delayr  1/icps + 2
;adelay  deltapi 1/kcps
asig    rand iamp
acomb         comb asig,  0.1, 1/icps
acomb1        comb asig, 0.1, 1/(2*icps)
acomb2        comb asig, 0.1, 1/(3*icps)
;ar       tone 3*(acomb+acomb1+acomb2), 1000
ar      streson acomb+acomb1+acomb2, icps, 0.90
arm     = ar * amod
;        delayw arm        
        out aenv*arm
        endin




       instr GBEG
       idur = p3
       iamp = p4
       icps = p5 
       itab = (p6>0)?p6:5 ; pluck envelope
       imod = (p7>0)?p7:2 ; mod cps 2-5 is good
aenv    adsr 0.01*idur,0.1*idur,0.9,0.1*idur
kres    = 0 ;line 0, p3, 1
;kres    oscili 1,0.5,
kcps = icps + kres
amod	oscili	1, imod, itab
asig    rand iamp
acomb         comb asig, 0.1, 1/icps
acomb1        comb asig, 0.1, 1/(2*icps)
acomb2        comb asig, 0.1, 1/(3*icps)
;ar       tone 3*(acomb+acomb1+acomb2), 2000
;ar       tone ar, 2000
ac = acomb + acomb1 + acomb2
ad distort1 ac, 6, 4, 0.1, 0.2
ad      clip ad, 1, 10000
ar      streson ad, icps, 0.90
arm     = ar * amod
arm    reverb2 arm, 1.5, 0.1
        out aenv*arm
        endin

                

       instr RepeatingGBEB
       iscaleAmp = (p4>0)?p4:1
       itab = (p6>0)?p6:5 ; pluck envelope
koscili oscili 1, 2, 1
kcps = gkgbegcps + koscili
amod	oscili	1, gkgbegmod, itab
asig    rand gkgbegamp
acomb vcomb asig, 1/kcps, 0.1, 0.1
acomb1 vcomb asig, 1/(2*kcps), 0.1, 0.1
acomb2 vcomb asig, 1/(3*kcps), 0.1, 0.1
ar = 3*(acomb+acomb1+acomb2)

ar        streson ar, kcps, 0.96
ac = ar
ad distort1 ac, gkgbegdist1, gkgbegdist2, 0.1, 0.2
ad      clip ad, 1, 30000
ar      streson ad, kcps, 0.90
arm     = ar * amod
arm    reverb2 arm, 1.5, 0.1
        out arm*iscaleAmp
        endin

        instr GBEGAmpSet
        p3 = 1/44100
        gkgbegamp = p4
        endin

        instr GBEGCpsSet
        p3 = 1/44100
        gkgbegcps = p4
        endin

        instr GBEGModSet
        p3 = 1/44100
        gkgbegmod = p4
        endin

        instr GBEGDist1Set
        p3 = 1/44100
        gkgbegdist1 = p4
        endin

        instr GBEGDist2Set
        p3 = 1/44100
        gkgbegdist2 = p4
        endin

