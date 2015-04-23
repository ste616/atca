#!/usr/bin/env perl

# Plot the execution times.

use PGPLOT;
use strict;

my %storage;

open(T, "execution_times.out");
while(<T>) {
    chomp;
    my $line = $_;

    if ($line =~ /^(CFB.*M) continuum smoothing (.*) zoom smoothing (.*) zoom width (.*?)\s(.*) avg (.*)$/) {
	if (!$storage{$1}) {
	    $storage{$1} = { 'continuum_smoothing' => [],
			     'zoom_smoothing' => [],
			     'zoom_width' => [],
			     'time' => [],
			     'max_time' => [] };
	}
	push @{$storage{$1}->{'continuum_smoothing'}}, $2;
	push @{$storage{$1}->{'zoom_smoothing'}}, $3;
	push @{$storage{$1}->{'zoom_width'}}, $4;
	push @{$storage{$1}->{'time'}}, $6;
	my @alltimes = split(/\,/, $5);
	push @{$storage{$1}->{'max_time'}}, &max(\@alltimes);
    }
}
close(T);

pgopen("11/xs");
pgswin(0, 17, 0, 120);
pgbox("BCNTS", 0, 0, "BCNTS", 0, 0);
pglab("Zoom width", "Execution time (s)", "");
my $orig = &collect("CFB1M", 1, 1, \%storage, 0);
pgpt($#{$orig->{'x'}} + 1, $orig->{'x'}, $orig->{'y'}, 2);
pgline($#{$orig->{'x'}} + 1, $orig->{'x'}, $orig->{'y'});
my $origmax = &collect("CFB1M", 1, 1, \%storage, 1);
pgpt($#{$origmax->{'x'}} + 1, $origmax->{'x'}, $origmax->{'y'}, 4);
pgsls(2);
pgline($#{$origmax->{'x'}} + 1, $origmax->{'x'}, $origmax->{'y'});
pgsls(1);
my $two = &collect("CFB64M", 1, 1, \%storage, 0);
pgsci(2);
pgpt($#{$two->{'x'}} + 1, $two->{'x'}, $two->{'y'}, 2);
pgline($#{$two->{'x'}} + 1, $two->{'x'}, $two->{'y'});
my $twomax = &collect("CFB64M", 1, 1, \%storage, 1);
pgpt($#{$twomax->{'x'}} + 1, $twomax->{'x'}, $twomax->{'y'}, 2);
pgsls(2);
pgline($#{$twomax->{'x'}} + 1, $twomax->{'x'}, $twomax->{'y'});
pgsls(1);
pgclos();

# Print out the results.
print "average (maximum) execution time in seconds, for specified zoom width\n";
printf "%4s %10s %10s\n", "", "CFB1M", "CFB64M";
for (my $i = 0; $i <= $#{$orig->{'x'}}; $i++) {
    printf "%4d  %3d (%3d)  %3d (%3d)\n", $orig->{'x'}->[$i], $orig->{'y'}->[$i], $origmax->{'y'}->[$i], $two->{'y'}->[$i], $twomax->{'y'}->[$i];
}

sub collect {
    my $corrmode = shift;
    my $continuum_smoothing = shift;
    my $zoom_smoothing = shift;
    my $data = shift;
    my $getmax = shift;

    my $output = { 'x' => [], 'y' => [] };
    for (my $i = 0; $i <= $#{$data->{$corrmode}->{'continuum_smoothing'}}; $i++) {
	if ($data->{$corrmode}->{'continuum_smoothing'}->[$i] ==
	    $continuum_smoothing &&
	    $data->{$corrmode}->{'zoom_smoothing'}->[$i] ==
	    $zoom_smoothing) {
	    push @{$output->{'x'}}, $data->{$corrmode}->{'zoom_width'}->[$i];
	    if ($getmax) {
		push @{$output->{'y'}}, $data->{$corrmode}->{'max_time'}->[$i];
	    } else {
		push @{$output->{'y'}}, $data->{$corrmode}->{'time'}->[$i];
	    }
	}
    }

    return $output;
}

sub max {
    my $aref = shift;
    my $mxa = $aref->[0];
    for (my $i = 1; $i <= $#{$aref}; $i++) {
	$mxa = ($aref->[$i] > $mxa) ? $aref->[$i] : $mxa;
    }
    return $mxa;
}
