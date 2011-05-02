sr=44100
kr=1102.5
ksmps=40
nchnls=1 

;; ignores duration
instr 1
	idur    = p3
        iiamp   = p4
	iicps	= p5
	icps	= iicps
	asig	init 0
	isize   filelen "samples/Piano001.wav"
	itime   = isize
	iddur   = itime/icps
        p3=iddur	
	kamp     linen iiamp*1,0.01,iddur,0.01
	asig diskin "samples/Piano001.wav" ,icps
        out       asig*kamp
endin

instr 2
	idur    = p3
        iiamp   = p4
	iicps	= p5
	icps	= iicps
	asig	init 0
	isize   filelen "samples/snare1.wav"
	itime   = isize
	iddur   = itime/icps
        p3=iddur	
	kamp     linen iiamp*1,0.01,(iddur),0.01
	asig diskin "samples/snare1.wav" ,icps
        out       asig*kamp
endin

instr 3
	idur    = p3
        iiamp   = p4
	iicps	= p5
	icps	= iicps
	asig	init 0
	isize   filelen "samples/1shot_gong.wav"
	itime   = isize
	iddur   = itime/icps
        p3=iddur	
	kamp     linen iiamp*1,0.01,(iddur),0.01
	asig diskin "samples/1shot_gong.wav" ,icps
        out       asig*kamp
endin

