#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use Config::IniFiles;
use CGI;
use Data::Dumper;

# For first step we'll be parse stdin args
my @users     = ();
my @text      = ();
my $sleep     = 0;
my $debug     = 0;
my $help      = 0;
my $community = 0;
GetOptions(
    'users=s{1,}' => \@users,
    'text=s{1,}'  => \@text,
    'delay=i'     => \$sleep,
    'debug'       => \$debug,
    'help'        => \$help,
    'community'   => \$community
);

my $message = join( ' ', @text );

# -----------

# Creating UserAgent for send message to VK
my $ua = LWP::UserAgent->new();
$ua->agent('VKSender/0.1');

my $vkmessage = 'https://api.vk.com/method/messages.send';

# ----------

my $cfg = Config::IniFiles->new( -file => "/etc/vkusers.ini" );

my $keys     = {};
my $hotchats = {};

# Getting tokens and names
my @params = $cfg->Parameters('Auth');

foreach my $tokname (@params) {
    $keys->{$tokname} = $cfg->val( 'Auth', $tokname );
}

# It's will be seen how $keys->{'glebtoken'} wich return 'TOKEN'
# ------

# Well, for hotchats it's seems method

my @chatnames = $cfg->Parameters('Hotchats');

foreach my $chatid (@chatnames) {
    $hotchats->{$chatid} = $cfg->val( 'Hotchats', $chatid );
}

# It's too will be seen how $hotchats->{'gyks'} will get his VK id.
# -----

# Now we'll compare our values from STDIN and ini

my @compareids = ();
foreach my $arg (@users) {
    foreach my $iniarg (@chatnames) {
        if ( $arg eq $iniarg ) {
            push @compareids, $hotchats->{$arg};
        }
    }
    if ( $arg =~ m/^(?|id\d+|\d+)/g ) {
        $arg =~ s/^id//g;
        push @compareids, $arg;
    }
}

# Sending....
foreach my $cmpid (@compareids) {
    my $prephash = {};
    if ( $community == 0 ) {
        $prephash = {
            'v'            => '5.80',
            'access_token' => $keys->{'glebtoken'},
            'peer_id'      => $cmpid,
            'message'      => $message
        };
    }
    else {
        $prephash = {
            'v'            => '5.80',
            'access_token' => $keys->{'commtoken'},
            'peer_id'      => $cmpid,
            'message'      => $message
        };
    }
    my $response = $ua->post( $vkmessage, $prephash );
    if ( $debug == 1 ) {
        print( Dumper($prephash) );
        my $content = $response->decoded_content();

        my $cgi = CGI->new();
        print $cgi->header(), $content;
        print("\n");

    }
    sleep($sleep);
}

# Help menu on --help
if ( $help == 1 ) {
    my $helpmsg = qq{
vksender 1.0 2018 Disinterpreter
    --users         List of users for send message to them
    --text          Message text
    --delay NUM     Delay between message in seconds
    --debug         Subj
    --community     Send from community
    Example: ./vksender --users disi --text 'what i did?' --delay 3 
--debug 1
};
    print( $helpmsg. "\n" );
}

