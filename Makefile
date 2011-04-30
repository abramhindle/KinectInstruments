
glview2: glview2.c
	gcc -std=c99 -I../include -DSDL=1 glview2.c -o glview2 -lGL -lglut -lSDL -lfreenect
difference: difference.c
	gcc -std=c99 -DSDL=1 -I../include difference.c -o difference -lGL -lglut -lSDL -lfreenect

play:	glview2
	sudo ./glview2 | perl filter.pl | csound -dm6 -o devaudio -L stdin sine2.orc sine2.sco
playdiff:	difference
	./difference |  csound -+rtaudio=alsa -dm6 -o devaudio -L stdin energy.orc energy.sco
energytest:	energy.orc
	csound -dm6 -o devaudio -L stdin energy.orc energy.sco

goopold:	goop.c
	gcc -std=c99 -I../include goop.c -o goop -lGL -lglut -lfreenect
goop:	goop-sdl.c	
	gcc -std=c99 -I../include -I/usr/include goop-sdl.c -o goop -lSDL -lfreenect

depth-game:	depth-game.c
	gcc -std=c99 -DSDL=1 -I../include depth-game.c -o depth-game -lSDL -lfreenect

play-depth-game:	depth-game
	./depth-game |  csound -dm6 -+rtaudio=alsa -o devaudio -L stdin energy.orc energy2.sco

playgoop:	goop energy.orc
	./goop |  csound -dm6 -+rtaudio=alsa -o devaudio -L stdin energy.orc energy.sco



playOsc:
	perl oscInstrument.pl | csound -dm6 -o devaudio -L stdin sine2.orc sine2.sco
playSkel:
	repos/OSCeleton/STDOUTeleton -w | perl stdouteletoninstrument.pl | csound -dm6 -o devaudio -L stdin sine2.orc sine2.sco


