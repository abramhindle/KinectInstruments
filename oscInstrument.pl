use Net::OpenSoundControl::Server;
use Data::Dumper qw(Dumper);
my @user = (0,0,0);
my @rhand = (0,0,0);
my @lhand = (0,0,0);
$| = 1;
sub dumpmsg {
    my ($sender, $message) = @_;
    
    my ($bundle,$n,@rest) = @$message;
    foreach my $r (@rest) {
        next unless ref $r;
        if ($r->[0] =~/\/user/) {
            $user[0] = $r->[2];
            $user[1] = $r->[4];
            $user[2] = $r->[6];
	    #warn "USER: ".join(" ", @user);
	} elsif ($r->[0] eq "/joint") {

#          [
#   0        '/joint',
#   1        's',
#   2        'l_hand',
#   3        'i',
#   4        1,
#   5        'f',
#   6        '0.80161190032959',
#   7        'f',
#   8        '0.557282984256744',
#   9        'f',
#   10       '1.86971604824066'
#          ],


	    next unless @$r == 11;
            my $joint = $r->[2];
            my $x = $r->[6];
            my $y = $r->[8];
            my $z = $r->[10];
	    my $loud = 300 - $z * 100;
            if ($joint eq "l_hand") {
		@lhand = ($x,$y,$z);
	        #warn "LHAND: $x $y $z";
            	print "i1 0.01 0.05 $loud ".2000*($x+$y).$/;
            } elsif ($joint eq "r_hand") {
		@rhand = ($x,$y,$z);
	        #warn "RHAND: $x $y $z";
            	print "i1 0.01 0.05 $loud ".(20 + 400 * $y).$/;
		if (distance(\@lhand, \@rhand) < 0.05) {
                    for my $f (40, 240, 1024) {            
                    	print "i1 0.01 0.50 200 ".$f.$/;
                    	print "i1 0.01 0.50 100 ".($f*2).$/;
                    	print "i1 0.01 0.50 100 ".($f/2).$/;
                    }
                }
            }
        }
    }
    #warn "[$sender] ", Dumper $message;
}

my $server = Net::OpenSoundControl::Server->new(
    Port => 7110, Handler => \&dumpmsg) or
    die "Could not start server: $@\n";

$server->readloop();

sub distance {
	my ($a, $b) = @_;
	my $sum = 0;
	while( @$a ) {
		my $x = pop @$a;
		my $y = pop @$b;
		my $d = $x - $y;
		$sum += $d * $d;
	}
	return sqrt($sum);
}
