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



(
SynthDef('help-dynKlang', {| freqs, amps, phases |
    Out.ar(0, DynKlang.ar(`[freqs, amps, phases]))
}).add
)

~arraysmaller = { |n,arr|
	var size = arr.size;
	Array.fill(n, {|i| arr[(size) * i/n]})
};
~arraysmaller.(10, Array.fill(100,{|i| i}));

~n = 10;
~freqs = Array.fill(~n, {|i| 20 + (i*50.0)});
~phases = Array.fill(~n, {|i| 1.0*i/~n})]);
a = Synth('help-dynKlang',[
	freqs: ~freqs,
	amps: Array.fill(~n, {0}),
	phases: ~phases]);
a.setn(\amps, Array.rand(~n, 0.0, 0.1));
a.setn(\amps, Array.rand(~n, 0.0, 0.1));
a.setn(\amps, Array.rand(~n, 0.0, 0.1));


~myKlangResponder = {
	|arr|
	a.setn(\freqs, ~freqs,
           \phases, ~phases,
           \amps, (~arraysmaller.(~n, arr)/1024));
};


OSCFunc.newMatching({|msg| "My Klang Listener".postln; ~myKlangResponder.( ~int8ArrayToInt32Array.(msg[1]))}, '/samples');


