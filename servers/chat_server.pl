#!/usr/bin/perl 
=head2 chat_server.pl

Perl chat server based on AnyEvent

Server:     perl $0
Clients:    telnet 127.0.0.1 8888 (run in severtal terminals)
            clients communicate by:
                                    a) sending message terninated with carriage return
                                    b) sending OK, followed by carriage return
                                       sending  message terninated with carriage return  

=cut

use strict;
use warnings;
use utf8;
use v5.018;

use AnyEvent;                           # creates event driven loop
use AnyEvent::Socket qw(tcp_server);    # provides high level function to create tcp server
use AnyEvent::Handle;                   # creates non-blocking (socket) handle

use Data::Dumper qw(Dumper);

sub _inform_clients;

=head2 Store connected clients in a hash structure

key:    $host:$port ..... uniquely identifies a connected client
value:  socket handle ... so we can continue communication with individual clients

=cut

my %client = ();

=head2 Create TCP server

allow connection from everywhere, on a specified port

=cut

tcp_server undef, 8888, sub {
    my ($fh, $host, $port) = @_;

    say "[$host:$port] connected";

=head3 On connection, tell the client how many are already connected

=cut

    syswrite $fh, "Hello friend. There are currently " . scalar(keys %client) . 
                  " connected friends.\015\012";

    _inform_clients(\%client, "Friend [$host:$port] joined us!");

=head3 Create unblocking socket handle for the client

=cut

    my $hdl = AnyEvent::Handle->new(
        fh => $fh,
    );

=head3 Store client information

=cut

    my $client_key = "$host:$port";
    $client{$client_key} = $hdl;

=head3 On error, clear the read buffer

=cut

    $hdl->on_error (sub {
        my $data = delete $_[0]{rbuf};
    });

=head3 On receiving a message from a client

We expect:

    sending a regular message
        either "OK\n", then a message
        or      directly a message
    disconnecting
        send quit/QUIT followed by carriage return

=cut

    my $writer; 
    $writer = sub {
        my ($hdl, $line) = @_;
        say "Reading from client: [$line]";

        my @clients = keys %client;
        say Dumper(\@clients);

        # The client cannot disconnect until we release its handle
        if ($line =~ /\Aquit|bye|exit\z/i) {

            my $client_count = (scalar keys %client) - 1;       # exclude the leaving client

            # Send message to each client
            for my $key (@clients) {

                if ($key eq $client_key) {
                    $hdl->push_write("Bye\015\012");
                }
                else {
                    my $message = ($client_count > 1) ? "only $client_count of us left\015\012" : 
                                                         "You are the only one left :(. Send quit/QUIT to disconnect\015\012";
                    $client{$key}->push_write("Friend $client_key is leaving us, $message");
                }

            }

            $hdl->push_shutdown;
            delete $client{$client_key};
            
        }
        # if we got an "OK", we have to _prepend_ another line,
        # so it will be read before the second request reads the 64 bytes ("OK\n")
        # which are already stored in the queue when this callback is called
        elsif ($line eq "OK") {
            $_[0]->unshift_read (line => sub {
                my $response = $_[1];
                for my $key (grep {$_ ne $client_key} @clients) {
                    $client{$key}->push_write("$response from $client_key\015\012");
                }
            });
        }
        elsif ($line) {
            for my $key (grep {$_ ne $client_key} @clients) {
                my $response = $line;
                $client{$key}->push_write("$response from $client_key\015\012");
            }
        }
    };

=head3  Enter the request handling loop

=cut

    $hdl->on_read (sub {
        my ($hdl) = @_;

        # Read what was sent, when request/message received
        # (then distribute the message)
        $hdl->push_read (line => $writer);
    });

};

=head3 Start the event loop

=cut

AnyEvent->condvar->recv; 

=head2 SUBROUTINES

_inform_clients

=cut

=head2 _inform_clients

sends a message to all known/stored clients

=cut

sub _inform_clients {
    my ($client_href, $message) = @_;

    for my $key (keys %$client_href) {
        $client{$key}->push_write("$message\015\012");
    }
}
