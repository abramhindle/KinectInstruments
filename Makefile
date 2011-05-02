CC=gcc -std=c99 -O3 -DSDL=1 -I../include -lGL -lglut -lSDL -lfreenect
CSOUND=csound -dm6 -+rtaudio=alsa -dm6 -o devaudio -L stdin
CSOUNDJACK=csound -dm6 -+rtaudio=jack -dm6 -o devaudio -L stdin -B 2048
glview2: glview2.c
	$(CC) glview2.c -o glview2 
difference: difference.c
	$(CC) difference.c -o difference 

play:	glview2
	./glview2 | perl filter.pl | $(CSOUND) sine2.orc sine2.sco
playfm:	glview2
	./glview2 | perl simple-filter.pl | $(CSOUND) fm-xy.orc fm-xy.sco
playfmjack:	glview2
	./glview2 | perl simple-filter.pl | $(CSOUNDJACK) fm-xy441.orc fm-xy.sco

playdiff:	difference
	./difference |  $(CSOUND) energy.orc energy.sco
energytest:	energy.orc
	$(CSOUND) energy.orc energy.sco

goopold:	goop.c
	$(CC) goop.c -o goop 
goop:	goop-sdl.c	
	$(CC)  goop-sdl.c -o goop

depth-game:	depth-game.c
	$(CC) depth-game.c -o depth-game

play-depth-game:	depth-game
	./depth-game |  $(CSOUND) energy.orc energy2.sco
play-depth-game-jack:	depth-game
	./depth-game |  $(CSOUNDJACK) energy441.orc energy2.sco

playgoop:	goop energy.orc
	./goop |  $(CSOUND) energy.orc energy.sco
playgoopjack:	goop energy.orc
	./goop |  $(CSOUNDJACK) energy441.orc energy.sco



playOsc:
	perl oscInstrument.pl | csound -dm6 -o devaudio -L stdin sine2.orc sine2.sco
playSkel:
	repos/OSCeleton/STDOUTeleton -w | perl stdouteletoninstrument.pl | csound -dm6 -o devaudio -L stdin sine2.orc sine2.sco


