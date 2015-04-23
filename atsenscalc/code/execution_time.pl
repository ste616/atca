#!/usr/bin/env perl

# This is a script used to calculate the amount of time it
# takes to run the new ATCA sensitivity calculator with various
# inputs.

use strict;

my $cmd = "python ./atsenscalc_commandline.py";
my $niters = 5; # Run the command this many times for each combo.
my @iterfreqs = ( 2100, 5500, 19000, 36000, 94000 );

# Begin looping.
my @args;
my @outargs;
open(OUT, ">execution_times.out");
for (my $corr_i = 0; $corr_i <= 1; $corr_i++) {
    # The correlator config loop.
    if ($corr_i == 0) {
	$args[0] = "-b CFB1M";
	$outargs[0] = "CFB1M";
    } else {
	$args[0] = "-b CFB64M";
	$outargs[0] = "CFB64M";
    }

    for (my $smooth_i = 1; $smooth_i <= 1; $smooth_i *= 2) {
	# The continuum smoothing loop.
	$args[1] = "-s ".$smooth_i;
	$outargs[1] = "continuum smoothing ".$smooth_i;

	for (my $zoomsmooth_i = 1; $zoomsmooth_i <= 1; $zoomsmooth_i *= 2) {
	    # The zoom smoothing loop.
	    $args[2] = "-y ".$zoomsmooth_i;
	    $outargs[2] = "zoom smoothing ".$zoomsmooth_i;

	    for (my $nzoom_i = 1; $nzoom_i <= 16; $nzoom_i++) {
		# The zoom width loop.
		$args[3] = "-W ".$nzoom_i;
		$outargs[3] = "zoom width ".$nzoom_i;

		my @extimes;
		for (my $iter = 1; $iter <= $niters; $iter++) {
		    # The repeat loop.
		    my $scmd = "/usr/bin/time -p -o time.out ".$cmd." ".join(" ", @args)." -f ".
			$iterfreqs[$iter - 1]." -z ".($iterfreqs[$iter - 1] - 100);
		    print $scmd."\n";
		    system $scmd. "> /dev/null";
		    open(C, "time.out");
		    while(<C>) {
			chomp;
			my $line = $_;
			if ($line =~ /^real\s+(.*)$/) {
			    print $line."\n";
			    push @extimes, $1;
			}
		    }
		    close(C);
		}

		print OUT join(" ", @outargs)." ".join(",", @extimes)." avg ".&avg(@extimes)."\n";
		
	    }
	}

    }
}
close(OUT);

sub avg {
    my @v = @_;
    my $s = 0.0;
    my $n = 0;
    for (my $i = 0; $i <= $#v; $i++) {
	$s += $v[$i];
	$n++;
    }

    if ($n > 0) {
	return ($s / $n);
    } else {
	return 0;
    }
}
