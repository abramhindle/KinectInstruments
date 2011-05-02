$| = 1;
my $lastframe = 0;
while(my $line = <>) {
	chomp($line);
	if ($line =~ /^MAX: /) {
		my ($crap, $frame, $xy, $mincolor, $middlecolor) = split(/ +/, $line);
		my $x = $xy % 640;
		my $y = int($xy / 640);
		my $closeness = (1024 - $mincolor) / 1024.0;
		print "i1 0 0 ".join(" ",map { sprintf("%0.03f", $_ ) } ($x , $y, $closeness )).$/;
		
		if ($lastframe != $frame) {
			$lastframe = $frame;
			warn "NEW FRAME!";
		}
	}
}

