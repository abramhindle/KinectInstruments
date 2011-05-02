#!/usr/bin/perl
use strict;
use List::Util qw(sum);
use Term::ANSIColor qw(:constants);
$| = 1;
my $lastframe = 0;
my @x = ();
my @y = ();
my @closeness = ();
my $count = 0;
while(my $line = <>) {
	chomp($line);
	if ($line =~ /^MAX: /) {
		my ($crap, $frame, $xy, $mincolor, $middlecolor) = split(/ +/, $line);
		my $x = $xy % 640;
		my $y = int($xy / 640);
		push @x, $x;
		push @y, $y;
		my $closeness = (1024 - $mincolor) / 1024.0;
		push @closeness, $closeness;
		
		if ($lastframe != $frame) {
			$lastframe = $frame;
			if ($count++ % 4 == 0) {
				my $x = (@x)?(sum( @x ) / scalar(@x)):0;
				my $y = (@y)?(sum( @y ) / scalar(@y)):0;
				my $closeness = (@closeness)?(sum( @closeness ) / @closeness):0;
				my $pitch = (480 - $y)/480.0 * 4 + 0.1;
				my $duration = abs(320 - $x)/320*0.3 + 0.1; #meaningless
				my $loudness = 0.01 + 0.99*$closeness;
				my $o = "i1 0.0001 ".join(" ",map { sprintf("%0.03f", $_ ) } ($duration, $loudness, $pitch)).$/;
				print $o;
				warn BOLD, RED, scalar(@x)." $x $y $closeness", RESET;
				warn BOLD, YELLOW, $o, RESET;
				warn "NEW FRAME!";

				@x = ();
				@y = ();
				@closeness = ();
			}
		}
	}
}

