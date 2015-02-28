#!/usr/bin/perl

=head2 plack_app1.pl

run: plackup -o localhost -p 8000 plack_app1.pl

=cut

use strict;
use warnings;
use v5.018;
use utf8;

use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;
 
use Plack::Request;
use CHI;

=head3 Cache messages for later display together with the latest message

messages are cached on the file system, so will survive the server restart
the storage is limited to 4kb

=cut

my $cache = CHI->new( driver => 'FastMmap',
    root_dir   => '/tmp/plack_app1_cache',
    cache_size => '4k');
my $cache_key = "${0}_message";
$cache->remove($cache_key);
 
=head3 Plackup subroutine reference

input:  hashref containing request information
output: arrayref of the prescribed format

=cut

my $app = sub {
    my $env = shift;

    # Create the HTML form where a message can be input
    my $html    = _create_form();

    # Wraps the $env in a Plack request object 
    my $request = Plack::Request->new($env);
     
    # Recover old messages for display, store them all
    my $old_messages = $cache->get($cache_key) || '';

    # The request is a sent form with filled in message field
    if ($request->param('message')) {

        say "[$request->param('message')]";

        my $current_message = $request->param('message');
        my $message = $old_messages . "<br />$current_message";
        $message = (length $message > 2000) ? $current_message : $message;
        $cache->set($cache_key, $message);

        # Append the messages to the form html
        $message = $old_messages . "<br /><b>$current_message</b>";
        $html  .= "You told me:<br />$message";
    }
    elsif ($old_messages) {
        $html  .= "Old messages: <br />$old_messages";
    }
 
    return [
            '200',
            [ 'Content-Type' => 'text/html' ],
            [ $html ],
        ];
};

=head2 SUBROUTINES

=head3 _create_form

=cut
 
sub _create_form {
    return q{
    <hr>
    <form>
        <input name="message">
        <input type="submit" value="Tell me">
    </form>
    <hr>
    }
}
