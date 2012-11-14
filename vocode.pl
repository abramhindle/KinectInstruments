#!/usr/bin/perl
use List::Util qw(shuffle sum min max);
use JSON;
use strict;
use Time::HiRes qw(time);
$| = 1;
my $startTime = time();
my $txt = "";
my %v = ();
open(my $fd,">","out.sco");
my $frames = 0;
#cs('"RepeatingGBEB"', 0, -1);
my $lastTime = time();
while (my $line = <>) {
    chomp;
    #warn "Got $line";
    my $time = time();
    my $fps = 1 / (0.0001 + $time - $lastTime);#$frames++ / ($time - $startTime);
    $frames++;
    print STDERR "FPS: $fps$/";
    my $h;
    eval {
        $h = decode_json $line;
    };
    next if $@;

    while (my ($key,$val) = each %$h) {
        my $name = $key;
        if (ref($val)) {
            for (my $i = 0; $i < @$val; $i++) {
                pushAdd($name.$i, $val->[$i]);
            }
            arrayPushAdd( $name, $val );
        } else {
            pushAdd( $name, $val );
        }
    }
    pushAdd( "mds", rollScaleScalar( "meandiff", $h->{meandiff}, 15*$fps ) );
    my $motion = rollAvg( "mds"  , $fps );
    pushAdd( "motion", $motion );
    my $sds = rollScaleScalar( "stddiff", $h->{stddiff}, 15*$fps) ;
    pushAdd( "sds", $sds );
    
    my $amp = 100 + 100 * $sds;
    pushAdd( "amp", 100 + 100 * $sds  );

    my $avgMotion = rollAvg( "motion", $fps );

    #my $cpsT = rollAvg("mds", 10) - rollAvg( "mds" , 5.0/3 * $fps );
    my $hist0 = $h->{hist0};
    my $hist7 = $h->{hist7};
    my $cps = 20 + 320 * (rollScaleScalar( "hist0", $hist0, 15 * $fps ) + rollScaleScalar( "hist7",$hist7, 5 * $fps )) ;
    
    my $hu0 = $h->{hu0};
    my $hus  = rollScaleScalar( "hu0", $hu0, 5.0/3 * $fps );
    pushAdd( "hus", $hus );
    my $mod = 1 + $hus;

    pushAdd("mod", $mod);

    my $spacial0 = $h->{"spacial-moments0"};
    my $scaleSpacial0  = rollScaleScalar("spacial-moments0",$spacial0, 20.0 * $fps );
    pushAdd("scaleSpacial0", $scaleSpacial0);    
    my $hucps = 320 + 1000*rollMax("scaleSpacial0",5.0  * $fps);

    pushAdd("hucps",$hucps);


    # smoothness
    my $diffMean = $h->{diffMean};
    my $diffMean50 = rollAvg("diffMean",$fps);
    
    my $diffSTD = $h->{diffSTD};
    my $diffSTD50 = rollAvg("diffSTD",$fps);

    my $semivariogram = $h->{semivariogram};
    my $semivariogram50 = rollAvg("semivariogram",$fps);
    



    # mirror

    my $meanmirror = $h->{meanmirror};
    my $meanmirror50 = rollAvg("meanmirror",$fps);
    
    my $stdmirror = $h->{stdmirror};
    my $stdmirror50 = rollAvg("stdmirror",$fps);

    
    cs('"dissonant"', rand(0.1), 0.1+rand(0.1), 8000, 40+$semivariogram, $semivariogram50/1000);#$index, exp(5*scaleSample($sample)), 40+exp(1.0+$index/12.0));#10*($index + 1));
    cs('"dissonant"', rand(0.1), 0.1+rand(0.1), 8000, 1000+$meanmirror, $meanmirror50/1000);#$index, exp(5*scaleSample($sample)), 40+exp(1

    # idea: one continuous tone with a bit of a LFO and then we can set both its pitch and its dissonance

    # idea: get the convex hull of the contours and simplify it. Then output the polygon.

    #if ($motion > $avgMotion) {
    #    cs('"DT3"', 0, 1.0, $amp, $cps);
    #}
    #if ($motion > $avgMotion + rollStd("stddiff")) {
    #  cs('"GB"'     ,0,1.0,$amp,$cps);
    #  cs('"GBNoise"',0,1.0,$amp,3*$cps);
    #}
    #if ($hus > rollAvg("hu0",50)) {
    #    cs('"GBNoise"'     ,0,1.0,$amp, $hucps);
    #}
    #if ($frames % 6 == 0) {
    #    cs("\"GBEGModSet\""     ,0,0, $mod);
    #    cs("\"GBEGCpsSet\""     ,0,0, $cps );
    #    cs("\"GBEGAmpSet\""     ,0,0, 0.01*$amp )    ;
    #}
    my $index = 0;
    sub scaleSample {
	my $sample = shift;
        my $s = ($sample - 300);
	return ((2048-300) - $s)/(2048-300);
    }
    foreach my $sample (@{$h->{samples}}) {
	#if ($sample >= 300) {
	#cs('666', rand(0.1),1, $index, ($sample >= 300)?100*(2048-($sample-300))/2048.0:0, 20*($index + 1));
	#}
	if ($sample >= 300) {
		cs('777', rand(0.1),0.1, $index, exp(5*scaleSample($sample)), 40+exp(1.0+$index/12.0));#10*($index + 1));
	}
	$index++;
    }
    $lastTime = $time;
}
sub rollScaleScalar {
    die "Not enough args in rollScaleScalr" unless @_ == 3;
    my ($name,$v,$n) = @_;   
    my @a = roll($name,$n);
    return 0 if (!@a);
    my $mi = min( @a);
    my $ma = max( @a);
    if ($mi == $ma) {
        return 0;
    }
    return ($v - $mi) / (1.0 * $ma - $mi);
}
sub pushAdd {
    my ($name,$value) = @_;
    $v{$name} = [] unless exists $v{$name};
    push @{$v{$name}}, $value;
}
sub arrayPushAdd {
    my ($name, $value) = @_;
    my $arr = $v{$name} || [ map { [] } @$value ];
    my $n = @$value;
    for ( my $i = 0; $i < $n; $i++ ) {
        push @{$arr->[$i]}, $value->[$i];
    }
    $v{$name} = $arr;    
}
sub roll {
    die "Not enough args in roll" unless @_ == 2;
    my ($name, $n) = @_;
    die "Not found! $name" unless exists $v{$name};
    my @a = @{$v{$name}} ;
    if (@a < $n) {
        return @a;
    }
    return @a[($#a - $n)..$#a];
}
sub rollAvg {
    die "Not enough args in rollAvg" unless @_ == 2;
    my ($name,$n) = @_;
    avg( roll($name, $n) );
}
sub rollMax {
    my ($name,$n) = @_;
    die "Not enough args in rollAvg" unless @_ == 2;
    my ($name,$n) = @_;

    my @r = roll( $name, $n );
    my $max = $r[0];
    foreach my $v ( @r )  {
        if ($v > $max) {
            $max = $v;
        }
    }
    return $max;    
}
sub scale {
    my @a = @_;
    my $mi = min( @a);
    my $ma = max( @a);
    if ($ma - $mi == 0) {
        return map { 1 } @a;
    }
    return map { ( $_ - $mi ) / ($ma - $mi) } @a;
}
sub rollScale {
    scale(roll(@_));
}
sub std {
    my @a = @_;
    sqrt(sum(map { $_*$_ } @a));
}
sub rollStd {
    my ($name,$n) = @_;
    std(roll($name,$n));
}
sub cs {
    my @a = @_;
    my $s = " \%f"x(scalar(@a) - 1);
    my $str = sprintf("i\%s $s$/", @a);
    print $str;
    $a[1] = time() - $startTime;
    $str = sprintf("i\%s $s$/", @a);
    print $fd $str;    
}
sub avg {
    return sum(@_)/(1.0*scalar(@_));
}
