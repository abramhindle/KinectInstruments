f1 0 16384 10 1 ; sine
f2 0 16384 10 1 .5 .333333 .25 .2 .166667 .142857 .125 .111111 .1 .090909 .083333 .076923 ; Saw
f3 0 16384 10 1 0  .333333 0   .2 0       .142857   0    .111111 0  .090909 0       .076923
 ; Square
f4  0 16384 10   1  .5 .333 .25 .2 .166 .142 .125 .111 .1 .09 .083 .076 .071 .066 .062 ; pluck
f5  0 16 2 1 1 0.75 0.25 0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.01 0.01

f 0 3600
; ; i"Harmonic" 0 0.3 4000 20  1
; ; i"Harmonic" 0.3 . 4000 40  1
; ; i"Harmonic" +   . 4000 80  1
; ; i"Harmonic" +   . 4000 160 1
; ; i"Harmonic" +   . 4000 320 1
; ; i"Harmonic" +   . 4000 640 1
; ; i"Harmonic" +   . 4000 1280 1
; ; 
; ; i"Harmonic" + 0.3 4000 20  2
; ; i"Harmonic" + . 4000 40  2
; ; i"Harmonic" +   . 4000 80  2
; ; i"Harmonic" +   . 4000 160 2
; ; i"Harmonic" +   . 4000 320 2
; ; i"Harmonic" +   . 4000 640 2
; ; i"Harmonic" +   . 4000 1280 2
; ; 
; ; i"Harmonic" + 0.3 4000 20  3
; ; i"Harmonic" + . 4000 40  3
; ; i"Harmonic" +   . 4000 80  3
; ; i"Harmonic" +   . 4000 160 3
; ; i"Harmonic" +   . 4000 320 3
; ; i"Harmonic" +   . 4000 640 3
; ; i"Harmonic" +   . 4000 1280 3
; ; 
; ;i"Harmonic" 0  1 4000 440 1
; ;i"Harmonic" 1  1 4000 880 1
; ;i"Harmonic" 2  1 4000 1000 1
; ;i"Harmonic" 3  1 4000 2000 1
; 
; ;i"Pluck"    4  2 100 100 
; ;i"Pluck"    6  2 100 200 
; ;i"Pluck"    +  2 100 300 
; ;i"Pluck"    +  2 100 400 
; ;i"Pluck"    +  2 100 500 
; ;i"Pluck"    4  10 100 600 
; ;i"ContPlucker"     0  10 1000   440
; ;i"ContPlucker"     0  10 1000   160
; ;i"DT" 0 1 1000 40
; ;i"DT" 2 1 1000 80
; ;i"DT" 3 1 1000 160
; ;i"DT" 4 1 1000 320
; ;i"DT" 5 1 1000 640
; ;i"DT" 6 1 1000 1280
; ;i"DT" 7 1 1000 2560
; ;i"DTHarm" 8 1 1000 40
; ;i"DTHarm" 9 1 1000 80
; ;i"DTHarm" 10 1 1000 160
; ;i"DTHarm" 11 1 1000 320
; ;i"DTHarm" 12 1 1000 640
; ;i"DTHarm" 13 1 1000 1280
; ;i"DTHarm" 14 1 1000 2560
; ;i"DT" 0 1 1000 40
; ;i"DT" 0 1 1000 80
; ;i"DT" 0 1 1000 160
; ;i"DT" 0 1 1000 320
; ;i"DT" 0 1 1000 640
; ;i"DT" 0 6 1000 1280
; ;i"DT" 0 6 1000 1300
; ;i"DT" 0 6 1000 1320
; ;i"DT3" 0 6 1000 160
; ;i"DT3" 6 6 1000 440
; ;i"DT3" 12 6 1000 666
; ;i"DT3" 0 3  1000 10
; ;i"DT3" 10 3 1000 20
; ;i"DT3" 15 3 1000 30
; ;i"DT3" 20 3 1000 40
; ;i"DT3" 25 3 1000 50
; ;
; ; 
; ; i"GB" 0  3 1000 30 5
; ; i"GB" 3  3 1000 40 5
; ; i"GB" 6  3 1000 50 5
; ; i"GB" 9  3 1000 60 5
; ; 
; ; i"GB" 12  3 1000 30 1
; ; i"GB" 15  3 1000 40 1
; ; i"GB" 18  3 1000 50 1
; ; i"GB" 21  3 1000 60 1
; ; 
; ; i"GB" 12  3 1000 30 2
; ; i"GB" 15  3 1000 40 2
; ; i"GB" 18  3 1000 50 2
; ; i"GB" 21  3 1000 60 2
; ; 
; ; i"GB" 24  3 1000 30 3
; ; i"GB" +  3 1000 40 3
; ; i"GB" +  3 1000 50 3
; ; i"GB" +  3 1000 60 3
; ; 
; ; i"GB" +  3 1000 30 4
; ; i"GB" +  3 1000 40 4
; ; i"GB" +  3 1000 50 4
; ; i"GB" +  3 1000 60 4
; ; 
; ; i"GB" 0  5 1000 40 4
; ; i"GB" 5  5 1000 80 3
; ; i"GB" 10  5 1000 120 2
; ; i"GB" 15  5 1000 160 1
; ; 
; 
; 
; 
; 
; 
; 
; 
; ;i"GB"  0  6  1000 246
; ;i"GB" 10 3 1000 80
; ;i"GB" 15 3 1000 160
; ;i"GB" 20 3 1000 320
; ;i"GB" 25 3 1000 640
; ;i"GB" 30 3 1000 4000
; ;;
; ; i"GBNoise" 0 4 1000 1000 5 20 ; gross ; skips
; ; i"GBNoise" + 4 1000 1000 5 16 ; gross ; skips
; ;i"GBNoise" + 4 1000 1000 5 8 ; too much skips
; ;i"GBNoise" 0 4 1000 1000 5 5 ; fast?
; ;i"GBNoise" + 4 1000 1000 5 4 ; 
; ;i"GBNoise" + 4 1000 1000 5 3 ;
; ;i"GBNoise" + 4 1000 1000 5 2 ;
; ;i"GBNoise" + 4 1000 1000 5 1 ; long and slow
; ;i"GBNoise" + 4 1000 260  5 5 ; fast?
; ;i"GBNoise" + 4 1000 260  5 4 ; 
; ;i"GBNoise" + 4 1000 260  5 3 ;
; ;i"GBNoise" + 4 1000 260  5 2 ;
; ;i"GBNoise" + 4 1000 260  5 1 ; long and slow
; ;i"GBNoise" + 4 1000 80  5 5 ; fast?
; ;i"GBNoise" + 4 1000 80  5 4 ; 
; ;i"GBNoise" + 4 1000 80  5 3 ;
; ;i"GBNoise" + 4 1000 80  5 2 ;
; ;i"GBNoise" + 4 1000 80  5 1 ; long and slow
; ;i"GBNoise" + 4 1000 80  3 5 ; fast?
; ;i"GBNoise" + 4 1000 80  . 4 ; 
; ;i"GBNoise" + 4 1000 80  . 3 ;
; ;i"GBNoise" + 4 1000 80  . 2 ;
; ;i"GBNoise" + 4 1000 80  . 1 ; long and slow
; ;i"GBNoise" + 4 1000 80  2 5 ; fast?
; ;i"GBNoise" + 4 1000 80  . 4 ; 
; ;i"GBNoise" + 4 1000 80  5 3 ;
; ;i"GBNoise" + 4 1000 80  5 2 ;
; ;i"GBNoise" + 4 1000 80  . 1 ; long and slow
; 
; 
; 
; ;i"GBEG" + 4 1000 40   5 0.5 ;
; ;i"GBEG" + 4 1000 80   . 1 ;
; ;i"GBEG" + 4 1000 160  . 2 ;
; ;i"GBEG" + 4 1000 320  . 3 ;
; ;i"GBEG" + 4 1000 640  . 4 ;
; 
; 
; ;i"GBNoise" 0 16 1000 1280 5
; ;i"GBNoise" 0 16 1000 260 5
; ;i"GBNoise" 0 16 1000 80 5
; ;i"GBNoise" 0 16 1000 40 5
; 
; ; i"GBNoise" 0  4 1000 40  4
; ; i"GBNoise" 4  . 1000 80  4
; ; i"GBNoise" 8  . 1000 120 4
; ; i"GBNoise" 12  . 1000 160 4
; ; i"GBNoise" 16  . 1000 260 4
; ; i"GBNoise" 20  . 1000 320 4
; ; 
; ; 
; ; i"GBNoise" 24  . 1000 40  3
; ; i"GBNoise" 28  . 1000 80  .
; ; i"GBNoise" 32  . 1000 120 .
; ; i"GBNoise" 36  . 1000 160 .
; ; i"GBNoise" 40  . 1000 260 .
; ; i"GBNoise" 44  . 1000 320 .
; ; 
; ; i"GBNoise" 48  . 1000 40  2
; ; i"GBNoise" 52  . 1000 80  .
; ; i"GBNoise" 56  . 1000 120 .
; ; i"GBNoise" 60  . 1000 160 .
; ; i"GBNoise" 64  . 1000 260 .
; ; i"GBNoise" 68  . 1000 320 .
; ; 
; ; i"GBNoise" 72  . 1000 40  1
; ; i"GBNoise" 76  . 1000 80  .
; ; i"GBNoise" 80  . 1000 120 .
; ; i"GBNoise" 84  . 1000 160 .
; ; i"GBNoise" 88  . 1000 260 .
; ; i"GBNoise" 92  . 1000 320 .
; 
; ;i"RepeatingGBEB" 0 1000 40
; 






 
; i"Harmonic" 0  1 4000  50 1 ; low horn sounding
; i"Harmonic" +  1 4000 100 1
; i"Harmonic" +  1 4000 200 1
; i"Harmonic" +  1 4000 400 1
; i"Harmonic" +  1 4000 800 1
; 
; i"DTHarm" 6  1 1000 40   ;deep is good
; i"DTHarm" +  1 1000 80  
; i"DTHarm" +  1 1000 160
; i"DTHarm" +  1 1000 320
; 
; i"Pluck"    10  1 1000 100 ; high pitched pluck
; i"Pluck"    +  1 1000 200 
; i"Pluck"    +  1 1000 300 
; i"Pluck"    +  1 1000 400 
; i"Pluck"    +  1 1000 500 
; 
; i"DT" 15  1 1000 40 ; noisey flute sound?
; i"DT" +  1 1000 80
; i"DT" +  1 1000 160
; i"DT" +  1 1000 320
; 
; i"ContPlucker"    0  1 1000 100 ; sorta harsh
; i"ContPlucker"    +  1 1000 200 ; not a great instrument
; i"ContPlucker"    +  1 1000 300 
; i"ContPlucker"    +  1 1000 400 
; i"ContPlucker"    +  1 1000 500 
; 
; i"DT3" 24  1 1000 40  ; harm video gameish
; i"DT3" +  1 1000 80
; i"DT3" +  1 1000 160
; i"DT3" +  1 1000 320
; 
; i"GB" 29  1 1000 40  ;Soft Harmonics
; i"GB" +  1 1000 80
; i"GB" +  1 1000 160
; i"GB" +  1 1000 320
; 
; i"GBNoise" 35  1 1000 40  ; vibrato strings?
; i"GBNoise" +  1 1000 80
; i"GBNoise" +  1 1000 160
; i"GBNoise" +  1 1000 320
; 
; i"GBEG" 40  1 1000 40
; i"GBEG" +  1 1000 80
; i"GBEG" +  1 1000 160
; i"GBEG" +  1 1000 320
