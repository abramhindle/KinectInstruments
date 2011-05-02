#!/usr/bin/perl
use Term::ANSIColor qw(:constants);
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
		$pitch = 40+10*(480-$y);#(480 - $y) + (320 - abs($x - 320)) - 100 * $closeness ; #(1 - sqrt(($x/640.0 - 320.0/640)**2 + ($y/480.0 - 240.0/480)**2)) * 400 + 10*rand() ;
		$loudness = 50 + 200*( $closeness);#100 + (abs($pitch) < 200)?(200-abs($pitch)):0;
		$duration = 0.1 + 0.3*abs($x - 320)/320;#0.5*(0.1 + (1-$y/480) + (1 - $x/640) + $closeness);
		my $o = "i1 0.0001 ".join(" ",map { sprintf("%0.03f", $_ ) } ($duration, $loudness, $pitch)).$/;
		warn BOLD, YELLOW, $o, RESET;
		print $o;
		
		if ($lastframe != $frame) {
			$lastframe = $frame;
			warn "NEW FRAME!";
		}
	}
}

