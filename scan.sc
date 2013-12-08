s.options.memSize = 650000;
s.boot;
s.scope;

~int8toint32l = { |l|
	(l[0] & 0xff << 0) | (l[1] & 0xff << 8) | (l[2] & 0xff << 16) | (l[3] & 0xff << 24)
};
~int8toint32 = { |l0,l1,l2,l3|
	(l0 & 0xff << 0) | (l1 & 0xff << 8) | (l2 & 0xff << 16) | (l3 & 0xff << 24)
};
~int8ArrayToInt32Array = { |l|
	var o = Int32Array.newClear(l.size / 4);
	forBy(0, l.size - 1, 4, { |i|
		o[i/4] = ~int8toint32.(l[i],l[i+1],l[i+2],l[i+3])
	});
	o	
};
~int8ArrayToInt32Array.(Int8Array[ -112, 3, 0 , 0, -112, 3, 0 , 0]);

~int8ArrayToInt32ArrayTest = {
	~arr = Int8Array[-112, 3, 0, 0];
	~int8to32l.(~arr).postln;
	~arr = Int8Array[-112, 3, 0, -1];
	~int8to32l.(~arr).postln;
	~arr = Int8Array[-112, 3, -1, 0];
	~int8to32.(~arr).postln;
	~arr = Int8Array[-112, 3, -1, 128];
	~int8to32l.(~arr).postln;
};

//~oscport = 57120;
//n = NetAddr("127.0.0.1", ~oscport); // local machine
//m = NetAddr("127.0.0.1", ~oscport); // local machine
//OSCFunc.newMatching({|msg| "My Listener".postln; ~int8ArrayToInt32Array.(msg[1]).postln}, '/samples');

/*

(
SynthDef('help-dynKlang', {| freqs=#[220, 440, 880, 1760],
    amps=#[0.35, 0.23, 0.12, 0.05],
    phases=#[1, 1.5, 2, 2.5]|

    Out.ar(0, DynKlang.ar(`[freqs, amps, phases]))
}).add
)

*/
~arraysmaller = { |n,arr|
	var size = arr.size;
	Array.fill(n, {|i| arr[(size) * i/n]})
};
~arraysmaller.(10, Array.fill(100,{|i| i}));

/*
~n = 10;
~freqs = Array.fill(~n, {|i| 20 + (i*50.0)});
~phases = Array.fill(~n, {|i| 1.0*i/~n});
~phases = Array.fill(~n, {0});
a = Synth('help-dynKlang',[
	freqs: ~freqs,
	amps: Array.fill(~n, {0}),
	phases: ~phases]);
//a.setn(\amps, Array.rand(~n, 0.0, 0.1));
//a.setn(\amps, Array.rand(~n, 0.0, 0.1));
//a.setn(\amps, Array.rand(~n, 0.0, 0.1));


~myKlangResponder = {
	|arr|
	var smaller = (~arraysmaller.(~n, arr)/1024);
	smaller.postln;
	~freqs.postln;
	~phases.postln;
	a.setn(\freqs, ~freqs,
           \phases, ~phases,
           \amps, smaller);
};

~myKlangResponder.([100,200,300,400,500,600,700,800,900,1000,1100]);
~myKlangResponder.([0,0,0,0,500,0,0,0,0,0,0]);

OSCFunc.newMatching({|msg| "My Klang Listener".postln; ~myKlangResponder.( ~int8ArrayToInt32Array.(msg[1]))}, '/samples');


~mamp = [ 0.826171875, 0.853515625, 0, 0, 0, 0, 0, 0.6376953125, 0.3759765625, 0.3603515625 ];
~mfreq = [ 20, 70, 120, 170, 220, 270, 320, 370, 420, 470 ];
~mphase = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];

*/

SynthDef('myklang', {| freqs=#[30,40,80,120,160,200,300,400,500,600],
    amps=#[0,0,0,0,0,0,0,0,0,0],
    phases=#[0,0,0,0,0,0,0,0,0,0]|
	Out.ar(0,
		Mix.ar(
			SinOsc.ar( freq: freqs, phase: phases, mul: amps)))
}).add;

SynthDef('myklang10', {|freqs=#[0,0,0,0,0,0,0,0,0,0],
	amps=#[0,0,0,0,0,0,0,0,0,0],
	phases=#[0,0,0,0,0,0,0,0,0,0]|
	Out.ar(0,
		Mix.ar(
			SinOsc.ar( freq: freqs, phase: phases, mul: amps)))
}).add;
SynthDef('myklang100', {|freqs=#[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	amps=#[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	phases=#[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	out=0|
	Out.ar(out,
		Mix.ar(
			SinOsc.ar( freq: freqs, phase: phases, mul: amps)))
}).add;



~n = 100;
~afreqs = Array.fill(~n, {|i| 20 + (i*15.0)});
~bfreqs = Array.fill(~n, {|i| 20 + (i*15.0)});

//~phases = Array.fill(~n, {|i| 1.0*i/~n});
~aphases = Array.fill(~n, {0});
~bphases = Array.fill(~n, {0.01});
~aamp = Array.fill(~n, {1/~n});
~bamp = Array.fill(~n, {0});
a = Synth('myklang100',[
	out: 0,
	freqs: ~afreqs,
	amps: ~aamp,
	phases: ~aphases]);
b = Synth('myklang100',[
	out: 1,
	freqs: ~bfreqs,
	amps: ~bamp,
	phases: ~bphases]);
~aold = Array.fill(~n, {0});
b.setn(\amps,Array.fill(~n, {|i| 0.01 }));
//~freqs
//a.setn(\freqs, Array.fill(~n, {|i| 1000.rand} ),
//       \amps, Array.fill(~n, {|i| (i/~n).rand} ));
//a.setn(    \amps, Array.fill(~n, {|i| (i/~n).rand} ));
//~amps = Array.fill(~n, {|i| 0.0 });
//~amps[~n-3] = 0.1;
//~amps;
//a.setn(\amps, ~amps);
OSCFunc.newMatching({|msg| 
	var out;
	"My Klang 100 Listener".postln; 
	// part a
	out = ~int8ArrayToInt32Array.(msg[1])/1024.0;
	~aold = (~aold * 0.9) + (0.1 * out);
	~afreqs = ~aold * 1200;
	~bamp = (~bamp * 0.9) + (0.1 * (out/~n));
	a.setn(\freqs, ~afreqs,
		\amps, Array.fill(~n,{0.01}));
	b.setn(
		\out, 1,
		\freqs, ~bfreqs,
		\amps, ~bamp);	       
}, '/samples');
