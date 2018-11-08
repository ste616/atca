#!/usr/bin/env perl

## Try to make the shadowing plots.
#use Math::Trig qw(asin_real acos_real atan2);
use Astro::Coord;
use PGPLOT;
use strict;

## Load the coordinates of each station.
my $FILEDIR = ".";

## Now load the coordinates of each station.
open(STATIONS,"$FILEDIR/station_coordinates.file");
my %stations;
my $long = 149.5489798;
my $pi = 3.141592654;
my $rlong = $long * $pi / 180.0;
my $coslong = cos(-$rlong);
my $sinlong = sin(-$rlong);
my $hlong = $long / 15.0;
while(<STATIONS>){
    chomp;
    my $line=$_;
    $line=~s/^\s*//;
    if ($line=~/^\#/){
	next;
    }
    my @els=split(/\s+/,$line);

    ## Rotate the system (currently pointing at Greenwich meridian)
    ## into local meridian.
    my ($gx, $gy, $gz) = @els;
    my $lx = $coslong * $gx - $sinlong * $gy;
    my $ly = $sinlong * $gx + $coslong * $gy;
    
    $stations{$els[3]} = { 'x' => $lx, 'y' => $ly,
			   'z' => $gz };
}
close(STATIONS);

## Now read in the names of each configuration and their
## Corresponding stations
my %configurations;
open(ARRAYS,"$FILEDIR/configuration_stations.file");
while(<ARRAYS>){
    chomp;
    my @els = split(/\s+/);
    $configurations{$els[0]} = {
	'ca01' => $els[1], 'ca02' => $els[2], 'ca03' => $els[3],
	'ca04' => $els[4], 'ca05' => $els[5], 'ca06' => $els[6]
    };
}
close(ARRAYS);

## Pick an array with a high likelihood of shadowing.
my $badarray = "H168";
## Which stations are in that array?
my $array = $configurations{$badarray};

my $min_length = 22.0;
## Go through and calculate shadowing for each hour angle and dec.
## We go through Decs in 1 degree increments, and 10 minutes in hour
## angle.
my $min_d = -90;
my $max_d = 30;
my $interval_d = 0.1;
my $nd = ($max_d - $min_d) / $interval_d;
my $min_h = -12.0;
my $max_h = 12.0;
my $interval_h = (1.0 / 60.0);
my $nh = ($max_h - $min_h) / $interval_h;
my @shadowflags;
my $lat = -30.3128846;
my $tlat = $lat / 360.0;
my $rlat = $lat * $pi / 180.0;
my $sinlat = sin($rlat);
my $coslat = cos($rlat);
for (my $di = 0; $di < $nd; $di++) {
    my $d = $min_d + $di * $interval_d;
    my $dt = $d / 360.0;
    my %tellim = ( 'ELLOW' => (12.0 / 360.0) );
    my $halim = haset_azel($dt, $tlat, %tellim);
    for (my $hi = 0; $hi < $nh; $hi++) {

	my $h = $min_h + $hi * $interval_h;
	my $ht = $h / 24.0;
	## Work out the az / el.
	my ($az, $el) = eqazel($ht, $dt, $tlat);
	$az *= 360.0;
	$el *= 360.0;
	my $raz = $az * $pi / 180.0;
	my $rel = $el * $pi / 180.0;
	my $sinel = sin($rel);
	my $cosel = cos($rel);
	my $sinaz = sin($raz);
	my $cosaz = cos($raz);
	## First, work out if this hour and dec is observable.
	if (abs($h) > (24.0 * $halim)) {
	    push @shadowflags, 1;
	    next;
	}
	my $ha = $h * 2.0 * $pi / 24.0;
	my $dec = $d * $pi / 180.0;
	my $sinh = sin($ha);
	my $cosh = cos($ha);
	my $sind = sin($dec);
	my $cosd = cos($dec);
	my $tshadow = 0;
	for (my $i = 1; $i <= 6; $i++) {
	    ## Get the XYZ of this antenna.
	    my $post1 = $array->{'ca0'.$i};
	    my $x1 = $stations{$post1}->{'x'};
	    my $y1 = $stations{$post1}->{'y'};
	    my $z1 = $stations{$post1}->{'z'};
	    for (my $j = 1; $j <= 6; $j++) {
		if ($i == $j) {
		    next;
		}
		my $post2 = $array->{'ca0'.$j};
		my $x2 = $stations{$post2}->{'x'};
		my $y2 = $stations{$post2}->{'y'};
		my $z2 = $stations{$post2}->{'z'};
		## Get the baseline.
		my $bx = $x2 - $x1;
		my $by = $y2 - $y1;
		my $bz = $z2 - $z1;
		## Calculate uvw.
		my $bxy = $bx * $sinh + $by * $cosh;
		my $byx = -$bx * $cosh + $by * $sinh;
		my $u = $bxy;
		my $v = $byx * $sind + $bz * $cosd;
		my $w = -$byx * $cosd + $bz * $sind;
		my $bl = sqrt($u * $u + $v * $v);
		if (($bl <= $min_length) && ($w > 1e-6)) {
		    $tshadow += 1;
		}
	    }
	}
	push @shadowflags, $tshadow;
    }
}

pgopen("testshadowing.png/png");
pgswin($min_d, $max_d, $min_h, $max_h);
pgbox("BCNTS", 0, 0, "BCNTS", 0, 0);
pgscir(0, 1);
print $nd." ".$nh."\n";
pggray(\@shadowflags, $nh, $nd, 1, $nh, 1, $nd,
       1, 0, [ ($min_d - $interval_d), 0, $interval_d, 
	       ($min_h - $interval_h), $interval_h, 0 ]);
pglab("declination", "hour angle", "shadowing");
pgclos();

