#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use v5.018;

use AnyEvent;
use AnyEvent::HTTP;         # Provides http_get, http_post etc methods

use Time::HiRes qw(time);

my @urls =  (   "https://www.google.com",
                "http://asdfgh.co.uk",
                "https://www.bing.com",
                "http://tmara-handmade-cards.co.uk",
                "http://yahoo.com",
            );

=head3 Event loop initialization

Creates a condition variable, which is initially false. The condition variable signals if an event was emmitted. Using ->send, it will become true and the event loop stops.
->recv starts the event loop. Can be used to receive results.

=cut

my $cv = AnyEvent->condvar;

=head3 Create request/get callback

=cut

my $start = time;

# ->send will be issued when all urls are processed
my $processed;

# HTTP responses are collected in:
my $received = '';

my $req_callback = sub {
    my ($body, $hdr) = @_;

    # non-existent website still returns status 200
    if ($hdr->{connection} && $hdr->{connection} eq 'close') {
        $received .= "\t2a) NOT AVAILABLE $hdr->{URL}: $hdr->{connection}\n";
    }
    # true success
    elsif ($hdr->{Status} =~ /^2/) {
        $received .= "\t2b) $hdr->{URL} - [$hdr->{Status} $hdr->{Reason}]\n";
    }
    # there is a problem of sorts
    else {
        $received .= "\t2c) ERROR $hdr->{URL} - [$hdr->{Status} $hdr->{Reason}]\n";
    }

    $processed++;

    # Send the collected HTTP responses after all urls are processed
    # which stops the event loop
    $cv->send($received) if $processed == scalar @urls;
};

=head3 Request the urls and process the responses

=cut

for my $url (@urls) {
    say "Getting $url";

    http_get $url, $req_callback;
}

=head3 Starts the event loop

Enters the event loop until $condvar receives ->send

=cut

my $outcome = $cv->recv;

say ">>>>>>>>>\n$outcome<<<<<<<<<<";
print "Total elapsed time: ", time-$start, " ms\n";

