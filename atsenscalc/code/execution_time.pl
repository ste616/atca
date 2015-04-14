#!/usr/bin/env perl

# This is a script used to calculate the amount of time it
# takes to run the new ATCA sensitivity calculator with various
# inputs.

use strict;

my $cmd = "python ./atsenscal_commandline.py";
my $niters = 5; # Run the command this many times for each combo.

# Begin looping.
my @args;
my @outargs;
for (my $corr_i = 0; $corr_i <= 1; $corr_i++) {
    # The correlator config loop.
    if ($corr_i == 0) {
	$args[0] = "-b CFB1M";
	$outargs[0] = "CFB1M";
    } else {
	$args[0] = "-b CFB64M";
	$outargs[0] = "CFB64M";
    }

    for (my $smooth_i = 1; $smooth_i <= 16; $smooth_i *= 2) {
	# The continuum smoothing loop.
	$args[1] = "-s ".$smooth_i;
	$outargs[1] = "continuum smoothing ".$smooth_i;

	for (my $zoomsmooth_i = 1; $zoomsmooth_i <= 16; $zoomsmooth_i *= 2) {
	    # The zoom smoothing loop.
	    $args[2] = "-y ".$zoomsmooth_i;
	    $outargs[1] = "zoom smoothing ".$zoomsmooth_i;

	    for (my $nzoom_i = 1; $nzoom_i <= 16; $nzoom_i++) {
		# The zoom width loop.
		$args[3] = "-W ".$nzoom_i;
		$outargs[3] = "zoom width ".$nzoom_i;

		for (my $iter = 1; $iter <= $niters; $iter++) {
		    # The repeat loop.
		    
		}

	    }

	}

    }
}
