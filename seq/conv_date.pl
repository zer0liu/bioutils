#!/usr/bin/perl

=head1 NAME

    conv_date.pl - Convert and replace date into day of year,
                   or decimal of year.

=head1 SYNOPSIS

=head1 DESCRIPTION

    Date of a sequence was identified by leading '@':

                    Description             Decimal of Year
    
    @2000:          Year only               2000.5
    @2000-06:       Year and month          2000.45
    @2000-06-25:    Year, month and date    2000.4822

    Date:               2015-01-15  2015-06-25
    Day of Year:        15          176
    Decimal of Year:    0.0411      0.4822

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.0.1   2015-01-14
    0.0.2   2015-10-12  New feature: Deal with 'yyyy-mm' date
    0.1.0   2017-04-06  New algorithm:
                        'yyyy'          => yyyy.0
                        'yyyy-mm'       => yyyy.0 + mm / 12 - 0.5
                        'yyyy-mm-dd'    => yyyy.0 + day of year / 365

=cut

use 5.010;
use strict;
use warnings;

use Date::Calc qw(Day_of_Year leap_year);
use File::Basename;
use Getopt::Long;

use Smart::Comments;

my $usage = << 'EOS';
Convert and replace date into day of year, or decimal of year.
Usage:
  conv_date.pl -i <in> -o <out> [-p <prefix>] [-m doy|dec]
Options:
  -i <in>       Input file.
  -o <out>      Output file. Optional.
  -p <prefix>   Prefix of date string. Default "@".
  -m dec|doy    Output format: decimal of year (default), or day of year.
NOTE:
  1. The accepted date format is "yyyy-mm-dd".
  2. It assumed that no other string behind the date after the prefix.
     i.e., "@yyyy-mm-dd$".
  3. For FASTA format input file ONLY.
EOS

my ($fin, $fout, $prefix, $ofmt);

$prefix = '@';
$ofmt   = 'dec';

GetOptions(
    "i=s"   => \$fin,
    "o=s"   => \$fout,
    "p=s"   => \$prefix,
    "m=s"   => \$ofmt,
    "h"     => sub { die $usage },
);

die $usage unless ( defined $fin );

# Generate output filename if necessary
unless (defined $fout) {
    my ($basename, $dir, $suffix)   = fileparse($fin, qr#\..*#);

    $fout   = $basename . '_doy' . '.' . $suffix;
}

open(my $fh_in, "<", $fin)
    or die "[ERROR] Open input file '$fin' failed!\n$!\n\n";

open(my $fh_out, ">", $fout)
    or die "[ERROR] Create output file '$fout' failed!\n$!\n\n";

while (<$fh_in>) {
    chomp;

    unless ( /^>/ ) {
        say $fh_out $_;
        next;
    }

    ## $_

    if ( /$prefix(\d+)\-(\d+)\-(\d+)$/ ) {    # yyyy-mm-dd
        my $year    = $1;
        my $month   = $2;
        my $day     = $3;

        $month  =~ s/^0//;
        $day    =~ s/^0//;

        if ( $ofmt eq 'dec' ) { # Convert to decimal of year, then output
            my $ydec = dec_of_year($year, $month, $day);

            s/$prefix.+?$/$prefix$ydec/;

            say $fh_out $_;
        }
        elsif ( $ofmt eq 'doy' ) {  # Output day of year
            my $doy =   Day_of_Year($year, $month, $day);

            my $ydoy    = $year . '.' . $doy;

            s/$prefix.+?$/$prefix$ydoy/;

            say $fh_out $_;
        }
        else {
            # Do nothing
        }
    }
    elsif ( /$prefix(\d+)\-(\d+)$/ ) {   # yyyy-mm
        my $year    = $1;
        my $month   = $2;
        # my $day     = '15';

        my $day;

        if ( $month eq '02' )   {   # Februray
            $day    = '14';
        }
        else {
            $day    = '15';
        }

        $month  =~ s/^0//;
        # $day    =~ s/^0//;

        if ( $ofmt eq 'dec' ) { # Convert to decimal of year, then output
            my $ydec = dec_of_year($year, $month, $day);

            s/$prefix.+?$/$prefix$ydec/;

            say $fh_out $_;
        }
        elsif ( $ofmt eq 'doy' ) {  # Output day of year
            my $doy =   Day_of_Year($year, $month, $day);

            my $ydoy    = $year . '.' . $doy;

            s/$prefix.+?$/$prefix$ydoy/;

            say $fh_out $_;
        }
        else {
            # Do nothing
        }

    }
    elsif ( /$prefix(\d+)$/ ) { # yyyy
        my $year    = $1;

        if ( $ofmt eq 'dec' ) { # Output decimal of year
            my $ydec    = $year + 0.5; 

            s/$prefix.+?$/$prefix$ydec/;

            say $fh_out $_;
        }
        elsif ( $ofmt eq 'doy' ) { # Output day of year

            my $doy = Day_of_Year($year, '6', '31');
            
            my $ydoy    = $year . '.' . $doy;

            s/$prefix.+?$/$prefix$ydoy/;

            say $fh_out $_;
        }
        else {
            # Do nothing
        }
    }
    else {
        say $fh_out $_;
    }
}

close $fh_out;

close $fh_in;

#===========================================================
#
#                   Subroutines
#
#===========================================================

=head2

  Name: dec_of_year($year, $momth, $day)
  Desc: Return decimal of year for a day.
  Args:
  Ret:  A numeric.

=cut

sub dec_of_year {
    my ($year, $month, $day)    = @_;

    my $doy =   Day_of_Year($year, $month, $day);

    my $dec;

    if ( leap_year( $year) ) {
        $dec    = sprintf("%.4f", $doy / 366);
    }
    else {
        $dec    = sprintf("%.4f", $doy / 365);
    }

    my $ydec =  $year + $dec;

    return $ydec;
}
