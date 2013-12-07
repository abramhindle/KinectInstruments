CSOUND=/usr/bin/csound -dm6 -+rtaudio=alsa -dm6 -o devaudio -L stdin
CSOUNDJACK=/usr/bin/csound -dm6 -+rtaudio=jack -dm6 -o devaudio -L stdin -B 2048
OPENCV=-lopencv_calib3d -lopencv_contrib -lopencv_core -lopencv_features2d -lopencv_flann -lopencv_gpu -lopencv_highgui -lopencv_imgproc -lopencv_legacy -lopencv_ml -lopencv_objdetect -lopencv_video 
SHAREDFLAGS=-DSDL=1 -lGL -lglut -lSDL -lfreenect -lm `pkg-config --cflags sdl` `pkg-config --cflags libfreenect` `pkg-config --libs sdl` `pkg-config --libs libfreenect` `pkg-config --cflags opencv` `pkg-config --libs opencv` -lpthread
CC=gcc -std=c99 -O3 
CPP=g++ -O3 -DSDL=1 -lGL -lglut -lSDL  ${SHAREDFLAGS} 

binaries:	glview2 difference goop depth-game KinectCV


glview2: glview2.c
	$(CC) glview2.c -o glview2 ${SHAREDFLAGS}
difference: difference.c
	$(CC) difference.c -o difference ${SHAREDFLAGS}

play:	glview2
	./glview2 | perl filter.pl | $(CSOUND) sine2.orc sine2.sco
playjack:	glview2
	./glview2 | perl filter.pl | $(CSOUNDJACK) sine2-44100.orc sine2.sco
playfm:	glview2
	./glview2 | perl simple-filter.pl | $(CSOUND) fm-xy.orc fm-xy.sco
playfmjack:	glview2
	./glview2 | perl simple-filter.pl | $(CSOUNDJACK) fm-xy441.orc fm-xy.sco

playdiff:	difference
	./difference |  $(CSOUND) energy.orc energy.sco
energytest:	energy.orc
	$(CSOUND) energy.orc energy.sco

goopold:	goop.c
	$(CC) goop.c -o goop $(SHAREDFLAGS)
goop:	goop-sdl.c	
	$(CC)  goop-sdl.c -o goop $(SHAREDFLAGS)

depth-game:	depth-game.c
	$(CC) depth-game.c -o depth-game $(SHAREDFLAGS)

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

KinectCV:	KinectCV.cpp
	$(CPP) KinectCV.cpp -o KinectCV $(SHAREDFLAGS)

KinectCVShape:	KinectCVShape.cpp
	$(CPP)  KinectCVShape.cpp -o KinectCVShape $(SHAREDFLAGS)

KinectCVShapeScan:	KinectCVShapeScan.cpp
	$(CPP)  KinectCVShapeScan.cpp -o KinectCVShapeScan $(SHAREDFLAGS)

play-shapeJack: KinectCVShape
	./KinectCVShape | perl vocode.pl |  $(CSOUNDJACK) 100sine.orc 100sine.sco

play-shape: KinectCVShape
	./KinectCVShape | perl vocode.pl | csound -dm6 -L stdin -o devaudio 100sine.orc 100sine.sco

play-KinectCV:	KinectCV
	./KinectCV | perl json-stats.pl | $(CSOUND) harmonics.orc harmonics.sco
play-KinectCVJack:	KinectCV
	./KinectCV | perl json-stats.pl | $(CSOUNDJACK) harmonics.orc harmonics.sco
