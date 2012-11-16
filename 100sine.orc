      	sr = 44100
	kr = 2205       
	ksmps = 20
	nchnls = 1

maxalloc 777, 200
maxalloc "Harmonic", 50
maxalloc "bell", 100
gkdnoise init 0
gkdbase init 60
gkdamp init 1000

        instr gkdnoiseset
        p3 = 1/44100
        gkdnoise = p4
        turnoff
        endin

        instr gkdbaseset
        p3 = 1/44100
        gkdbase = p4
        turnoff
        endin

        instr gkdampset
        p3 = 1/44100
        gkdamp = p4
        turnoff
        endin



	instr	1
iindex      =   p4
itableamp   =   2
itablepitch =   3
kpitch  table iindex, itablepitch
kamp    table iindex, itableamp
a1	oscili	kamp, kpitch, 1
	out	a1
	endin

        instr 666
p3      =     1/44100
;p3      =     1.0/88200
iindex  =     p4	; index
iloud   =     p5	; 
ipitch  =     p6     ;
itableamp =   2
itablepitch = 3
tableiw     iloud  , iindex, itableamp,   0, 0, 0 
tableiw     ipitch , iindex, itablepitch, 0, 0, 0 
endin


        instr 777
;p3      =     1/44100
p3      =     3/19.0
idur    = p3
iindex  =     p4	; index
iloud   =     p5	; 
ipitch  =     p6     ;
;ifenv  = 51                    ; bell settings:
ifenv  = 53                    ; bell settings:
aenv    oscili  1, 1/idur, ifenv             ; envelope
a1	oscili	iloud, ipitch, 1
out a1*aenv
endin


; p4 is 0-30000 
; p5 is 20-20000
instr bell
  idur   = p3
  iamp   = p4
  ifenv  = 51                    ; bell settings:
  ifdyn  = 52                    ; amp and index envelopes are exponential
  ifq1   = 5*p5/5;cpspch(p5)*5          ; decreasing, N1:N2 is 5:7, imax=10
  if1    = 1                     ; duration = 15 sec
  ifq2   = 7*p5/5;cpspch(p5)*7
  if2    = 1
  imax   = 10
  
  aenv  oscili  iamp, 1/idur, ifenv             ; envelope
  
  adyn  oscili  ifq2*imax, 1/idur, ifdyn        ; dynamic
  amod  oscili  adyn, ifq2, if2                 ; modulator
  
  a1    oscili  aenv, ifq1+amod, if1            ; carrier
        out     a1
endin

instr dissonant
      idur = p3
      iamp = p4
      ibase = p5
      inoise = p6 ; preferrably 0 to 1 but it will jostle the harmonics
      ;      ipeak = max(ibase,p7)
      inoise = (inoise > 1)?1:inoise
      ibasefreq random 1, 9
      knoise lfo ibase, 1/ibasefreq, 1
      aenv     adsr 0.1*idur, 0.1*idur, 0.3*idur, 0.5*idur
      imin = 1
      imax = 7
      adump  delayr 0.001+1/ibase      ; we ignore this value
      adelay deltapi 0.01;1/ibase

      ires1 random imin, imax
      ires2 random imin, imax
      ires3 random imin, imax
      ires4 random imin, imax
      ires5 random imin, imax
      ires6 random imin, imax
      ires7 random imin, imax
      itotal = 1/ires1 + 1/ires2 + 1/ires3 + 1/ires4 + 1/ires5 + 1/ires6 + 1/ires6
      kinoise = inoise * (1 + abs(knoise))
      asinewave1	oscili	iamp*(1/ires1), 1*(ibase + kinoise), 1
      asinewave2	oscili	iamp*(1/ires2), 2*(ibase + kinoise), 1
      asinewave3	oscili	iamp*(1/ires3), 3*(ibase + kinoise), 1
      asinewave4	oscili	iamp*(1/ires4), 4*(ibase + kinoise), 1
      asinewave5	oscili	iamp*(1/ires5), 5*(ibase + kinoise), 1
      asinewave6	oscili	iamp*(1/ires6), 6*(ibase + kinoise), 1
      asinewave7	oscili	iamp*(1/ires7), 7*(ibase + kinoise), 1
      asum = (1/itotal)*(asinewave1 + asinewave2 + asinewave3 + asinewave4 + asinewave5 + asinewave6 + asinewave7)/8 + inoise * adelay / 8
      delayw asum                 
      out aenv * asum 
endin


instr dissonant2
      idur = p3
      iamp = p4
      ibase = p5
      inoise = p6 ; preferrably 0 to 1 but it will jostle the harmonics
      ;      ipeak = max(ibase,p7)
      inoise = (inoise > 1)?1:inoise
      ibasefreq random 1, 9
      knoise lfo ibase, 1/ibasefreq, 1
      aenv     adsr 0.1*idur, 0.1*idur, 0.3*idur, 0.5*idur
      imin = 1
      imax = 7
      adump  delayr 0.001+1/ibase      ; we ignore this value
      adelay deltapi 0.01;1/ibase

      kres1 randomh imin, imax, 1/ibasefreq
      kres2 randomh imin, imax, 1/ibasefreq
      kres3 randomh imin, imax, 1/ibasefreq
      kres4 randomh imin, imax, 1/ibasefreq
      kres5 randomh imin, imax, 1/ibasefreq
      kres6 randomh imin, imax, 1/ibasefreq
      kres7 randomh imin, imax, 1/ibasefreq
      ktotal = 1/kres1 + 1/kres2 + 1/kres3 + 1/kres4 + 1/kres5 + 1/kres6 + 1/kres6
      kinoise = inoise * (1 + abs(knoise))
      asinewave1	oscili	iamp*(1/kres1), 1*(ibase + kinoise), 1
      asinewave2	oscili	iamp*(1/kres2), 2*(ibase + kinoise), 1
      asinewave3	oscili	iamp*(1/kres3), 3*(ibase + kinoise), 1
      asinewave4	oscili	iamp*(1/kres4), 4*(ibase + kinoise), 1
      asinewave5	oscili	iamp*(1/kres5), 5*(ibase + kinoise), 1
      asinewave6	oscili	iamp*(1/kres6), 6*(ibase + kinoise), 1
      asinewave7	oscili	iamp*(1/kres7), 7*(ibase + kinoise), 1
      asum = (1/ktotal)*(asinewave1 + asinewave2 + asinewave3 + asinewave4 + asinewave5 + asinewave6 + asinewave7)/8 + inoise * adelay / 8
      delayw asum                 
      out aenv * asum 
endin





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


instr globaldissonant
      idur = p3
      knoise randi gkdbase,60
      kres lfo 1, 1/7, 0
      kbase = gkdbase + 10*kres
      asinewave1	oscili	(1/1), 1*kbase + gkdnoise*(1-0)*knoise, 1
      asinewave2	oscili	(1/2), 2*kbase + gkdnoise*(2-0)*knoise, 1
      asinewave3	oscili	(1/3), 3*kbase + gkdnoise*(3-0)*knoise, 1
      asinewave4	oscili	(1/4), 4*kbase + gkdnoise*(4-0)*knoise, 1
      asinewave5	oscili	(1/5), 5*kbase + gkdnoise*(5-0)*knoise, 1
      asinewave6	oscili	(1/6), 6*kbase + gkdnoise*(6-0)*knoise, 1
      asinewave7	oscili	(1/7), 7*kbase + gkdnoise*(7-0)*knoise, 1
      aout = (asinewave1 + asinewave2 + asinewave3 + asinewave4 + asinewave5 + asinewave6 + asinewave7)/7
      ;      ares reson aout, kbase*4, gkdbase
      ;asig balance ares, aout
      out gkdamp*aout
endin

