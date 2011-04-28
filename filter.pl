$| = 1;
my $lastframe = 0;
while(my $line = <>) {
	chomp($line);
	if ($line =~ /^MAX: /) {
		my ($crap, $frame, $xy, $mincolor, $middlecolor) = split(/ +/, $line);
		my $x = $xy % 640;
		my $y = int($xy / 640);
		my $closeness = (1024 - $mincolor) / 1024.0;
		my ($pitch, $loudness, $duration) = (0,0,0);
		if ($x > 320) {
			$pitch = (1 - sqrt(($x/640.0 - 320.0/640)**2 + ($y/480.0 - 240.0/480)**2)) * 400 + 10*rand() ;
			$loudness = $closeness * 100;
			$duration = 0.5 - 0.49 * $closeness;
		} else {
			$duration = 0.01 + 0.01*rand();
			$pitch = 1000 + 10 * rand()+ 1000 * $closeness;
			$loudness = 100*$y/480;
			
		}
		print "i1 0.0001 ".join(" ",map { sprintf("%0.03f", $_ ) } ($duration, $loudness, $pitch)).$/;
		
		if ($lastframe != $frame) {
			$lastframe = $frame;
			warn "NEW FRAME!";
		}
	}
}

