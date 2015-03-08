#!/usr/bin/perl
#===============================================================================
#
#         FILE: thread_pool.pl
#
#        USAGE: perl thread_pool.pl 
#
#  DESCRIPTION: script comparing job processing done by one thread and a pool
#               of threads. Jobs are added to a job queue, from which they are
#               taken one by one by a thread that is available to do the work.
#               Both implementations are non-blocking.
#
#               two implementations:
#                   a) no pool/one thread only:
#                           one work queue and one thread taking jobs put on the work queue
#                   b) a pool of threads, that are taking jobs off a work queue
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Tamara Kaufler (), 
#      CREATED: 07/03/15 16:39:42
#===============================================================================

use strict;
use warnings;
use utf8;
use v5.018;

use threads;
use threads::shared;
use Thread::Queue;

my ($t0_a, $t1_a, $t0_b, $t1_b, $td_a, $td_b);

use List::Util qw(sum);
use Data::Printer;
use Benchmark qw(timediff timestr);

local $|;
my $MAX_THREADS  = 5;
my $data_dir     = './test';

my %work_queue   = ();
my @results      = ();
my $files_count  = 0;

opendir my $dh, $data_dir || die "can't opendir $data_dir $!";

my @files        = grep { /a*\.txt/ } readdir $dh;
$files_count     = scalar @files;

closedir $dh;

say "\n*************************************************";
say "*** Jobs: one job == processed file ***";
say "*************************************************\n";
p @files;

# Job queue
my $q = Thread::Queue->new();

# Add jobs to the job queue
$q->enqueue(@files);

say "\n*************************************************";
say "*** One thread takes jobs off a job queue ***";
say "*************************************************\n";
say "Pending jobs:";
p $q->pending();

=head2 One thread

Each thread will take work off the work queue
while work is available

=cut

$t0_a = Benchmark->new;

my $thr = threads->create(
    sub {
        my $sum = 0;

        # Thread will loop until no more work
        #   using ->dequeue will block the execution
        #   when there are no jobs to be done, unless 
        #   another mechanism takes care of that
        #   and handles the empty job queue
        while (defined (my $file = $q->dequeue_nb())) {
            my $incr_sum = _get_file_sum("$data_dir/$file");   
            $sum += $incr_sum; 
        }
        return $sum;
    }
);

{
    my @thr_results = map { $_->join() } threads->list();

    p $q->pending();

    $t1_a = Benchmark->new;
    $td_a = timestr(timediff($t1_a, $t0_a));

    p @thr_results;
    say "Done: sum is " . sum @thr_results;
    say "Run time = $td_a";
}

=head2 Pool of threads

=cut

say "\n*************************************************";
say "*** A pool of threads: each thread takes jobs off\nthe job queue while jobs are available ***";
say "*************************************************\n";
say "Pending jobs after the previous processing:";
p $q->pending();

# Send work to the thread
$q->enqueue(@files);

# Signal that there is no more work to be sent
# $q->end();

say "Pending jobs:";
p $q->pending();

$t0_b = Benchmark->new;

$MAX_THREADS = ($MAX_THREADS > $files_count) ? $files_count : $MAX_THREADS;
say "\nCreating a pool of $MAX_THREADS threads\n";

for (1 .. $MAX_THREADS) {;
    my $thr = threads->create(
        sub {
            my $sum = 0;

            # Thread will loop until no more work
            #   using ->dequeue will block the execution
            #   when there are no jobs to be done, unless 
            #   another mechanism takes care of that
            #   and handles the empty job queue
            while (defined (my $file = $q->dequeue_nb())) {
                my $incr_sum = _get_file_sum("$data_dir/$file");   
                $sum += $incr_sum; 
            }
            return $sum;

        }
    );
}

=head3 Wait for all threads to finish and collect all results

=cut

{
    my @thr_results = map { $_->join() } threads->list();

    p $q->pending();
    p @thr_results;

    $t1_b = Benchmark->new;
    $td_b = timestr(timediff($t1_b, $t0_b));

    say "Done: sum is " . sum @thr_results;

    say "Run time when 1 queue => $td_a";
    say "Run time when $MAX_THREADS threads => $td_b";
}

exit(0);

=head2 PRIVATE METHODS

=head3 _get_file_sum

=cut

sub _get_file_sum {
    my ($file) = @_;

    open my $fh, '<', $file or die "$!";

    #sleep int(rand(5));
    sleep 1;

    my $work;
    while (my $line = <$fh>) {
        chomp $line;
        $work += $line;
    }

    say "\t\tFile $file: sum = $work" if defined $work;

    return $work;
}
