#!/usr/bin/perl
use List::Util qw(shuffle sum min max);
use JSON;
use Data::Dumper;
use strict;
use Time::HiRes qw(time);
use Term::ANSIColor;
$| = 1;
my @attrs = @ARGV;
@ARGV=();
my $startTime = time();
my $txt = "";
my %v = ();
open(my $fd,">","out.sco");
my $frames = 0;
#cs('"RepeatingGBEB"', 0, -1);
my $lastTime = time();
while (my $line = <STDIN>) {
    chomp;
    #warn "Got $line";
    my $time = time();
    my $fps = 1 / (0.0001 + $time - $lastTime);#$frames++ / ($time - $startTime);
    $frames++;
    print STDERR "FPS: $fps$/";
    my $h;
    eval {
        $h = decode_json $line;
        for my $attr (@attrs) {
            print color 'yellow';
            print "$attr: ".(ref($h->{$attr}))?Dumper($h->{$attr}):$h->{$attr};
            print color 'reset';
            print $/;
        }
    };
    if ($@) {
        warn $@;
    }
}
