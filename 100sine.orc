      	sr = 44100
	kr = 2205       
	ksmps = 20
	nchnls = 1

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
      knoise randi ibase,60
      aenv     adsr 0.1*idur, 0.1*idur, 0.3*idur, 0.5*idur
      asinewave1	oscili	iamp*(1/1), 1*ibase + inoise*(1-0)*knoise, 1
      asinewave2	oscili	iamp*(1/2), 2*ibase + inoise*(2-0)*knoise, 1
      asinewave3	oscili	iamp*(1/3), 3*ibase + inoise*(3-0)*knoise, 1
      asinewave4	oscili	iamp*(1/4), 4*ibase + inoise*(4-0)*knoise, 1
      asinewave5	oscili	iamp*(1/5), 5*ibase + inoise*(5-0)*knoise, 1
      asinewave6	oscili	iamp*(1/6), 6*ibase + inoise*(6-0)*knoise, 1
      asinewave7	oscili	iamp*(1/7), 7*ibase + inoise*(7-0)*knoise, 1

      out aenv*(asinewave1 + asinewave2 + asinewave3 + asinewave4 + asinewave5 + asinewave6 + asinewave7)/7
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

