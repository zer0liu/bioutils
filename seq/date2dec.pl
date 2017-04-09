#!/usr/bin/perl

=head1 NAME

    date2dec.pl - Convert date to year decimal.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2016-05-27

=cut

use 5.010;
use strict;
use warnings;

use Date::Calc qw(Day_of_Year leap_year);

use Smart::Comments;

my $usage   = <<"EOS";
Convert date to year decimal.
Usage:
  date2dec.pl <date>
Note:
- Input date format: yyyy-mm-dd
EOS

my $date    = shift or die $usage;

my ($year, $month, $day);

if ($date =~ /^(\d{4})\-(\d{2})\-(\d{2})/) {
    $year   = $1;
    $month  = $2;
    $day    = $3;
}
else {
    die "[ERROR] Input date format: 'yyyy-mm-dd'.\n";
}

# Day of year
my $doy = Day_of_Year($year, $month, $day);

### Day of year: $doy
my $dec;

if (leap_year($year)) {
    $dec    = sprintf "%.4f", $doy / 366;
}
else {
    $dec    = sprintf "%.4f", $doy / 365;
}

# Output
say $year + $dec;

exit 0;
