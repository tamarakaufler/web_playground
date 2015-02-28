#!/usr/bin/perl 

=head2 parallel_workerq.pl

two implementations of forking child processes

=cut

use strict;
use warnings;
use utf8;
use v5.018;

use Parallel::ForkManager;
use POSIX":sys_wait_h";

use Time::HiRes qw(time);
use Data::Printer;

my $pm = Parallel::ForkManager->new(4);

=head3 Process all files in parallel

loops through all the files to be processed
creates/forks child processes
reaps deal child processes

2 implementations:
    a) with Parallel::ForkManager
    b) with fork:
        1) uses CHILD signal handler
        2) uses waitpid

=cut

my @files = qw(a b c d e f g);
my %child = ();

# creating child processes: implementation 1
# ==========================================

DATA_LOOP:
foreach my $data (@files) {
    
    # forks a new child process
    my $pid;
    $pid = $pm->start and say "... child $pid" and next DATA_LOOP;

    # what will be done in the child process
    # until ->finish is encountered
    sleep 3;

    # end the child process
    $pm->finish;
}

$pm->wait_all_children;
say ">>> DONE 1";

# creating child processes: implementation 2
# ==========================================

# child handler to reap dead children
# -----------------------------------
$SIG{CHLD} = sub {
    while ( (my $pid = waitpid(-1, WNOHANG)) > 0 ) {
        if (exists $child{$pid}) {
            delete $child{$pid};
            say "!!! deleted $pid";
        }
        return unless keys %child;
    }
};

foreach my $data (@files) {

    # create a child process
    # the flow execution goes until the 
    # end of the block
    my $pid = fork;

    # child process --------------------
    if ($pid) {
        say "* in the child process $pid";
        $child{$pid} = undef;
        sleep 3;
    } 
    # parent process
    elsif ($pid == 0) {
        # the parent process needs to exit
        # otherwise the flow execution will 
        # continue after the foreach loop
        # producing multiple 'DONE 2 statements'
        # instead of just one
        exit 0;
    }
    # failure to fork
    else {
        say "* failed to fork a process";
    }

    say "* still processing in child process $pid";
    # ----------------------------------
}

### reaping dead child processes without child signal handler
###     to use: comment out the CHILD gignal handler
###     and uncomment lines below
## ---------------------------------------------------
##while (keys %child) {
##    for my $key (keys %child) {;
##        my $pid = waitpid($key, WNOHANG);
##
##        if ($pid == -1) {
##            "\t>>> child $key does not exist";
##            delete $child{$key}; 
##
##            say "\t\t deleted key $key";
##        }
##
##        if ($pid == $key) {
##            delete $child{$key}; 
##
##            say "\t\t *** child $key reaped";
##            say "\t\t *** deleted key $key";
##        }
##        say ">>>--------------------------";
##    }
##}
##

p %child;
say ">>> DONE 2";

