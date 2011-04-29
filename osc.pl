use Net::OpenSoundControl::Server;
use Data::Dumper qw(Dumper);

sub dumpmsg {
    my ($sender, $message) = @_;
    
    print "[$sender] ", Dumper $message;
}

my $server = Net::OpenSoundControl::Server->new(
    Port => 7110, Handler => \&dumpmsg) or
    die "Could not start server: $@\n";

$server->readloop();

