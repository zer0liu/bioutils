#!/usr/bin/perl

=head1 NAME

    dec2date.pl - Convert year decimal to date of year.

=head1 SYNOSPIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2015-12-23

=cut

use 5.010;
use strict;
use warnings;

use Date::Calc qw(Add_Delta_Days leap_year);

use Smart::Comments;

my $usage   = << "EOS";
Convert year decimal to date of year.
Usage:
  dec2date <ydec>
EOS

my $ydec = shift or die $usage;

say "Dec:\t", $ydec;

my $year    = int $ydec;
my $dec     = $ydec - $year;

## $year
## $dec

my $doy;    # Day of year

if (leap_year($year)) { # Is leap year
    $doy    = int($dec * 366);
}
else {  # Not a leap year
    $doy    = int($dec * 365)
}

## $doy

my ($yyyy, $mm, $dd)  = Add_Delta_Days($year, 1, 1, $doy - 1);

$yyyy   = sprintf "%04d", $yyyy;
$mm     = sprintf "%02d", $mm;
$dd     = sprintf "%02d", $dd;

say "Date:\t", join '-', ($yyyy, $mm, $dd);

exit 0;

