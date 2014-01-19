#!/usr/bin/perl
#
## Shownote Bot

use strict;
use warnings;
use utf8;

use Log::Log4perl qw(:easy);

use Data::Dumper;
use Config::Simple;
use File::Basename;

use AnyEvent;
use AnyEvent::IRC::Client;

use LWP::Simple;
use JSON;

# make a new config config object
my $currentpath = dirname(__FILE__);
my $cfg         = new Config::Simple("$currentpath/bot.config");

# some global variables
my $programpath = 
my $account     = '';
my $msg         = "";
my $syn         = 0;

my $c = AnyEvent->condvar;
my $timer;
my $con = new AnyEvent::IRC::Client;
my $ircserver = $cfg->param('server');
my $port =  $cfg->param('port');
my $mynick =  $cfg->param('nick');
my $joinchan =  $cfg->param('channel');

# Log config
Log::Log4perl->init("$currentpath/logging.config");

# LoadPads
sub getPads {

  my ($search) = @_;
  my @results;

  # make a JSON parser object
  my $json = JSON->new->allow_nonref;

  # get JSON via LWP and decode it to hash
  INFO("Get Pads from api.shownot.es");
  my $rawdata = get( "http://api.shownot.es/getList" );
  my $pads    = $json->decode($rawdata);

  foreach my $pad (@$pads) {
    if ( $pad->{'group'} eq 'pod' and $pad->{'docname'} =~ m/^$search.*$/) {
      push(@results, 'http://pad.shownot.es/doc/'.$pad->{'docname'});
    }
  }
  sort @results;
}


# Event Registrierung
$con->reg_cb (connect => sub {
  my ($con, $err) = @_;
  if (defined $err) {
    warn "connect error: $err\n";
    return;
  }
  print "Connected!\n";
});

$con->reg_cb (registered => sub { 
  print "I'm in!\n";
});

$con->reg_cb (disconnect => sub { 
  print "I'm out!\n"; 
  $c->broadcast
});

$con->reg_cb ( sent => sub {
  my ($con) = @_;
  
  if ($_[2] eq 'PRIVMSG') {
     print "Sent message!\n";
  }
});

$con->reg_cb( join => sub {
  my ($con, $nick, $channel, $is_myself) = @_; 
  if ($is_myself && $channel eq $joinchan) {
  }
});

$con->reg_cb( publicmsg => sub {
  my ($irc, $channel, $msg) = @_;
  my $comment    = $msg->{params}->[1];
  
  $msg->{prefix} =~ m/^(.*)!.*$/;
  my $user = $1;
  
  if ($comment eq "!parser") {
    $con->send_chan( $channel, PRIVMSG => $channel => "http://tools.shownot.es/parsersuite/" );
  }
  
  if ($comment eq "!osf") {
    $con->send_chan( $channel, PRIVMSG => $channel => "http://shownotes.github.io/OSF-in-a-Nutshell/OSF-in-a-Nutshell.de.html" );
  }
  
  if ($comment =~ m/^!pads (.*)$/ ) {
    my @results  = getPads($1);
    $con->send_srv(PRIVMSG => $user, "Results:");
    
    my $i = 0;
    foreach my $link (@results) {
      $i++;
      $con->send_srv(PRIVMSG => $user, $link);
      if ($i == 4){
        $i = 0;
        sleep 2;
      }
    }
  }
  

  #$con->send_chan( $channel, PRIVMSG => ($channel, 'Just a debug message…') );
  #$con->send_chan( $channel, PRIVMSG => ($channel, 'Just a debug message…') );
  #$timer = AnyEvent->timer ( 
  #      after => 1,
  #     cb => sub {
  #         undef $timer;
  #         $con->disconnect('done');
  #     });
});



$con->connect ("$ircserver", "$port", { nick => "$mynick" });

#$con->send_srv (PRIVMSG => 'Dr4k3', "Hello there I'm the cool AnyEvent::IRC test script!");

$con->send_srv( JOIN => ("$joinchan") );

$c->wait;

$con->disconnect;
