use strict;
use Net::OpenSoundControl::Server;
use Data::Dumper qw(Dumper);
use Term::ANSIColor qw(:constants);
my %players = ();
my %player_age = ();

$| = 1;
my $counter = 0;
while(my $line = <STDIN>) {
    $counter++;
    chomp( $line );
    my @v = split(/\s+/, $line );
    #warn @v;
    if ($v[0] =~/user/) {
        #@user[0,1,2] = @v[1,2,3];
    } elsif ($v[0] eq "joint") {
        my ($jointname, $joint, $player, $x,$y,$z) = @v;
        my $loud = 300 - $z * 100; 
        $players{$player} = {} unless $players{$player};
        $player_age{$player} = {} unless $player_age{$player};
	my $body = $players{$player};
        my $age = $player_age{$player};
        next unless  (defined($x));
	$body->{$joint} = [$x,$y,$z];
        my $current = $body->{$joint};
        $age->{$joint} = $counter;
        if ($joint eq "r_hand") {# || $joint eq "l_hand") {
            #print "i1 0.0 0.05 $loud ".(20 + 400 * $y).$/;
            while( my ($njoint, $njoint_xyz) = each %$body) {
                next if $njoint eq $joint;
                # get rid of reflexive thing
                # next if ($joint eq "l_hand" && $njoint eq "r_hand");
                next if $age->{$njoint} < $counter - 1000; # too old
                my @xyz = @$njoint_xyz;
                next if @xyz != 3;
                my $distance = distance( $njoint_xyz, $current );
                if (defined($distance) && $distance < 0.1) {
                    warn "$joint: $x $y $z && $njoint: ".join(" ",@xyz);
                    warn BLUE()."Distance of $distance between ".RED().$joint.BLUE()." and ".RED().$njoint.RESET();
		    warn RED()."$joint touches $njoint".RESET();
                    print "i1 0.0 0.01 1000 20$/";
                    print "i1 0.0 0.01 1000 200$/";
                    print "i1 0.0 0.01 1000 2000$/";
                }
            }
        }
        if (rand() > 0.9) {
            my @keys = keys %$body;
            foreach my $k1 ("l_hand","r_hand") {
                foreach my $k2 (@keys) {
                    warn "$k1 $k2 :".sprintf("%0.03f",(distance($body->{$k1},$body->{$k2})||0));
                }
            }
        }
    }
}

sub distance {
	my ($arr1, $arr2) = @_;
	my $sum = 0;
        if (!defined($arr1) || !defined($arr2) || ref($arr1) != 'ARRAY' || ref($arr2) != 'ARRAY' ||
            (scalar(@$arr1) != scalar(@$arr2))) {
            return undef;
        }
        my @arr1 = @$arr1;
        my @arr2 = @$arr2;
        for(my $i = 0; $i <= $#arr1; $i++) {
		my $x = $arr1[$i];
		my $y = $arr2[$i];
		my $d = $x - $y;
		$sum += $d * $d;
	}
	return sqrt($sum);
}
