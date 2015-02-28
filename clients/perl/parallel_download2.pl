#!/usr/bin/perl

use strict;
use warnings;
use strict;
use v5.018;

use AnyEvent;
use AnyEvent::HTTP;

use Time::HiRes qw(time);

my $urls =  [   
                "https://www.google.com",
	            "http://asdfgh.co.uk",
	            "https://www.bing.com",
	            "http://tmara-handmade-cards.co.uk",
                "http://yahoo.com",
	        ];

=head3 Creates a condition variable

    corresponds to a signal that will be triggered by ->send
    which will stop the event loop, started by ->recv

    starting as false, becomes true after ->send is issued

=cut

my $cv = AnyEvent->condvar( cb => sub {
    say "\t*** Processing urls in parallel";
});

my $result;
my $start = time;

=head3 ->begin and ->end combine multiple transactions

    each ->begin increments a counter
    each ->end decrements the counter
    all transations share the same ->recv 

    when the counter becomes 0, the last callback (corresponding here to the first ->begin)
        will be excecuted
    the callback receives the $condvar, which can be used to ->send the collected result,
        which will be received by ->recv

=cut

# after all urls are processed, send the collected results
# to be received by ->recv
$cv->begin(sub { shift->send($result) });

for my $url (@$urls) {
    say ">>> Processing $url";

    # ----> group transations
    $cv->begin;

    my $now = time;
    my $request;  
    $request = http_get $url,
                    sub {
                        my ($body, $hdr) = @_;

                        if ($hdr->{Status} =~ /^2/) {
                            push @$result, 
                               join "\t", ($url,
                                            " content length ",
                                            $hdr->{'content-length'}, 
                                            "load time ",
                                            (time-$now) . "ms");
                        } else {
                            push @$result, 
                               join "\t", ("Error for $url",
                                            "HTTP status", 
                                            $hdr->{Status}, 
                                            $hdr->{Reason});
                        }

                        undef $request;

                        # ----> end of the transations group
                        $cv->end;
                    };
}

$cv->end;

my $outcome =   $cv->recv;

say join("\n", @$outcome) if $outcome;

say "Total elapsed time: ", time-$start, " ms";

