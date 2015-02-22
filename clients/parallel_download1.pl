#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use v5.018;

use Data::Dumper qw(Dumper);

use AnyEvent;
use AnyEvent::HTTP;         # Provides http_get, http_post etc methods

#use Benchmark;

my @urls = qw(http://www.amazon.co.uk/Head-First-Java-Kathy-Sierra/dp/0596009208/ref=pd_bxgy_b_img_z http://linkedin.com/ http://yahoo.com/ http://search.cpan.org/dist/AnyEvent/lib/AnyEvent.pm http://asrqewdx.com/ http://www.amazon.co.uk/Head-First-Design-Patterns-Freeman/dp/0596007124/ref=pd_bxgy_b_text_y);

=head3 Event loop initialization

Creates a condition variable, which is initially false. The condition variable signals if an event was emmitted. Using ->send, it will become true and the event loop stops.
->recv starts the event loop. Can be used to receive results.

=cut

my $cv = AnyEvent->condvar;

=head3 Create request/get callback

=cut

my $processed;
my $req_callback = sub {
    my ($body, $hdr) = @_;

    # non-existent website still returns status 200
    if ($hdr->{connection} && $hdr->{connection} eq 'close') {
        say "\t2a) $hdr->{URL}: $hdr->{connection}\n";
    }
    # true success
    elsif ($hdr->{Status} =~ /^2/) {
        say "\t2b) $hdr->{URL}";
        #say "$hdr->{URL}:\n\t$body\n";
    }
    # there is a problem of sorts
    else {
        say "\tERROR $hdr->{URL}";
        say "\t$hdr->{Status} $hdr->{Reason}\n";
    }

    $processed++;

    # Stop the event loop after all urls were processed
    $cv->send if $processed == scalar @urls;
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

$cv->recv;

