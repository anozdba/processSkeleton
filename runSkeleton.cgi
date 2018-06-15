#!/usr/bin/perl
# --------------------------------------------------------------------
# runSkeleton.cgi
#
# $Id: runSkeleton.cgi,v 1.3 2018/06/15 05:26:39 db2admin Exp db2admin $
#
# Description:
# Script to process the skeleton passed as the first parameter
#
# Usage:
#  runSkeleton.cgi <skeleton> [parameters as dictated by the skeleton]
#
# $Name:  $
#
# ChangeLog:
# $Log: runSkeleton.cgi,v $
# Revision 1.3  2018/06/15 05:26:39  db2admin
# add in an output type of HTTPDL to allow web downloads
#
# Revision 1.2  2018/06/14 05:19:34  db2admin
# when it looks like the script is acceting input from the web default the
# outputMode to HTTP
#
# Revision 1.1  2018/06/14 00:00:55  db2admin
# Initial revision
#
#
# --------------------------------------------------------------------

use strict;

my $machine;            # machine name
my $machine_info;       # ** UNIX ONLY ** uname
my @mach_info;          # ** UNIX ONLY ** uname split by spaces
my $OS;                 # OS
my $scriptDir;          # directory where the script is running
my $tmp;

BEGIN {
  if ( $^O eq "MSWin32") {
    $machine = `hostname`;
    $OS = "Windows";
    $scriptDir = 'c:\udbdba\scrxipts';
    $tmp = rindex($0,'\\');
    if ($tmp > -1) {
      $scriptDir = substr($0,0,$tmp+1)  ;
    }
  }
  else {
    $machine = `uname -n`;
    $machine_info = `uname -a`;
    @mach_info = split(/\s+/,$machine_info);
    $OS = $mach_info[0] . " " . $mach_info[2];
    $scriptDir = "scripts";
    $tmp = rindex($0,'/');
    if ($tmp > -1) {
      $scriptDir = substr($0,0,$tmp+1)  ;
    }
  }
}

use lib "$scriptDir";

use processSkeleton qw(processSkeleton skelVersion formatSQL $skelDebugLevel $skelCache $ctlCache testRoutine $testRoutines $outputMode $skelShowSQL $DBIModule $skelDebugModules);
use commonFunctions qw(getOpt myDate trim $getOpt_optName $getOpt_optValue @myDate_ReturnDesc $myDate_debugLevel $getOpt_diagLevel $getOpt_web $getOpt_calledBy);
use calculator qw(calcVersion evaluateInfix $calcDebugLevel $calcDebugModules);

$getOpt_diagLevel = 0;
$getOpt_calledBy = $0;
my $QUERY_STRING = $ENV{'QUERY_STRING'};
if ( $QUERY_STRING ne '' ) { $outputMode = 'HTTP' ; } # if the $QUERY_STRING variable has information it has probably come from the web 

# Usage subroutine

my $ID = '$Id: runSkeleton.cgi,v 1.3 2018/06/15 05:26:39 db2admin Exp db2admin $';
my @V = split(/ /,$ID);
my $Version=$V[2];
my $Changed="$V[3] $V[4]";

sub usage {

  # display a usage message and an error message (if supplied)

  if ( $#_ > -1 ) {
    if ( trim("$_[0]") ne "" ) {
      print "\n$_[0]\n\n";
    }
  }

  my $nl = "<BR>";

  if ( $outputMode ne "HTTP" ) {
    $nl = "";
  }

  print STDERR "Usage: $0 <skeleton> -?hs [-v[v]] [-S] [other parameters as dictated by the skeleton] $nl
  $nl
       Version $Version Last Changed on $Changed (UTC)  $nl
  $nl
       -h or -?           : This help message  $nl
       -s                 : Silent mode (limit displayed output)  $nl
       -S                 : ignores the skeleton parameter and writes all output to STDOUT $nl
       -v                 : set debug level  $nl
       <skeleton>         : the skeleton to be processed $nl
       [other parameters] : parameters as specified on \"Input Parameter\" statements in the skeleton $nl
  $nl
       This script will generate output based on the instructions detailed in the passed skeleton $nl
  $nl
       NOTE: The skeleton name MUST appear before all other parameters but the order of all other $nl
             parameters is generally not important $nl
  $nl ";
}

my $today;           # today's date in YYYMMDD format
my $yesterday_date;  # yesterday's date in YYYY-MM-DD format

sub generateDates {

  # calculate some date values and initialise some variables

  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  my $year = 1900 + $yearOffset;
  $month = $month + 1;
  $hour = substr("0" . $hour, length($hour)-1,2);
  $minute = substr("0" . $minute, length($minute)-1,2);
  $second = substr("0" . $second, length($second)-1,2);
  $month = substr("0" . $month, length($month)-1,2);
  my $day = substr("0" . $dayOfMonth, length($dayOfMonth)-1,2);
  $today = "$year$month$day";
  my @T = myDate("DATE\:$today"); # get today's day number
  my $today_daynum = $T[5];
  my $yesterday_daynum = $today_daynum - 1; # generate yesterday's daynum
  my @Y = myDate("$yesterday_daynum"); # work out yesterday's date
  $yesterday_date = "$Y[2]-$Y[1]-$Y[0]";
}

# before it goes too far check to see what is in the skeleton (and check that a valid skeleton has been passed)

if ( $#ARGV == -1 ) { # MUST have at least 1 parameter
  usage("this script requires at least 1 parameter that points to an existing skeleton file");
  exit;
}

if ( ! open( SKELFILE, "<", $ARGV[0] ) ) { # file not able to be read
  my $lastcc = $!;
  usage("Unable to open file $ARGV[0]\nError: $lastcc\n");
  exit;
}

# save the skeleton name
my $skeleton = $ARGV[0];
my $debugLevel = 0;
# do a quick check to see if debug mode will be set later
for ( my $i = 0 ; $i <= $#ARGV ; $i++ ) { 
  if ( $ARGV[$i] =~ /^-.*v/ ) { $debugLevel = 1 ; last; } # a debug parameter is set
}
my %skelParms = ();
my $parmString = ":h?sSvV:";
my $typeOfUse = 'STDOUT';
$DBIModule = '';
my %DBIParameter = ();

while (<SKELFILE>) { 
  if ( $_ =~ /End.*Control Information/ ) { last; } # indicates that no further control information in file so finish
  if ( uc(substr($_,0,3)) eq ")CM" ) { # it is a comment so may be a driver parameter
    if ( $_ =~ /Input Parameter/ ) { # input parameter ....
      my ($prm, $var) = ( $_ =~ /Input Parameter: \((.*)\)\s*(\S*)/ );
      $parmString .= "$prm:";
      $skelParms{$prm} = $var;
      if ( $debugLevel > 0 ) { print STDERR "From Skeleton ($skeleton): Parm $prm read in and assigned to $var\n"; }
    }
    elsif ( $_ =~ /Type of use/ ) { # type of output
      my ($tou) = ( $_ =~ /Type of use:\s*(\S*)/ );
      if ( " WEB HTTP " =~ uc($tou) ) { # does it require web related output?
        $typeOfUse = 'HTTP';
        $outputMode = 'HTTP';
      }   
      elsif ( " HTTPDL " =~ uc($tou) ) { # Is it a web download?
        $typeOfUse = 'HTTP';
        $outputMode = 'HTTPDL';
      }   
      else {
        $typeOfUse = 'STDOUT';
        $outputMode = 'STDOUT';
      }
      if ( $debugLevel > 0 ) { print STDERR "From Skeleton ($skeleton): Type of use is $typeOfUse\n"; }
    }
    elsif ( $_ =~ /Requires DBI/ ) { # type of output
      my ($DBIPrm) = ( $_ =~ /Requires DBI:\s*(\S*)/ );
      if ( defined($DBIPrm) ) { # DBI required
        $DBIModule = $DBIPrm;
      }
      if ( $debugLevel > 0 ) { print STDERR "From Skeleton ($skeleton): DBI Module required: $DBIModule\n";  }
    }
    elsif ( $_ =~ /DBI Parameter/ ) { # type of output
      my ($prm, $var) = ( $_ =~ /DBI Parameter : \((.*)\)\s*(\S*)/ );
      $DBIParameter{$prm} = $var;
      if ( $debugLevel > 0 ) { print STDERR "From Skeleton ($skeleton): DBI Parm $var read in and assigned to $prm\n"; }
    }
  }
}

close SKELFILE;

if ( $debugLevel > 0 ) { print STDERR "Parameter string : $parmString\n"; }

if ( $outputMode eq 'HTTP' ) {
  print "Content-type: text/html\r\n\r\n";
}

if ( $outputMode eq 'HTTPDL' ) { $outputMode = 'HTTP'; }

# Set parameter defaults

$debugLevel = 0;
my $silent = "No";
my $skelParameters = '';
my $parmCount = 0;

# ----------------------------------------------------
# -- Start of Parameter Section
# ----------------------------------------------------

# Initialise vars for getOpt ....

$getOpt_optName = "";
$getOpt_optValue = "";

while ( getOpt($parmString) ) {
 $parmCount++;
 if (($getOpt_optName eq "h") || ($getOpt_optName eq "?") )  {
   usage ("");
   exit;
 }
 elsif ( $getOpt_optName eq "s" )  {
   $silent = "Yes";
 }
 elsif ( $getOpt_optName eq "S" )  {
   $outputMode = 'STDOUT';
   if ( $silent ne "Yes" ) { print STDERR "Output will be formatted for a terminal\n"; }
 }
 elsif ( $getOpt_optName eq "v" )  { # debug option set
   $skelDebugLevel++;
   $calcDebugLevel++;
   $debugLevel++;
   if ( $skelParameters eq '' ) { 
     $skelParameters = 'SKL_SHOWSQL=YES';
   }
   else {
     $skelParameters .= ',SKL_SHOWSQL=YES';
   }
   if ( $silent ne "Yes" ) { print STDERR "Debug level now set to $debugLevel\n"; }
   # print out the arguments ......
   print STDERR ">>>> $#ARGV\n";
   for ( my $i = 0 ; $i <= $#ARGV ; $i++ ) {
     print STDERR "$i: $ARGV[$i]\n";
   }

   # do the same with any parameters returned from the web
   print STDERR ">>>> Environment string QUERY_STRING :\n";
   my @QS = split(" ", $QUERY_STRING);
   for ( my $i = 0 ; $i <= $#QS ; $i++ ) {
     print STDERR "$i: $QS[$i]\n";
   }
 }
 elsif ( $getOpt_optName eq "V" )  {
   $skelDebugModules = $getOpt_optValue;
   $calcDebugModules = $getOpt_optValue;
   if ( $silent ne "Yes" ) { print STDERR "Debug module will be $getOpt_optValue\n"; }
 }
 # Parameters beyond here will be dynamically added via the skeleton
 elsif ( defined( $skelParms{$getOpt_optName} ) ) { # it was defined in the skeleton
   if ( $skelParameters eq '' ) { 
     $skelParameters = "$skelParms{$getOpt_optName}=$getOpt_optValue";
   }
   else {
     $skelParameters .= ",$skelParms{$getOpt_optName}=$getOpt_optValue";
   }
   if ( $debugLevel > 0 ) { print STDERR "Skeleton Parameter: $skelParameters\n"; }
 }
 elsif ( $getOpt_optName eq ":" ) {
   usage ("Parameter $getOpt_optValue requires a parameter");
   exit;
 }
 else { # handle other entered values ....
   if ( $parmCount == 1 ) { # if it is the first parameter dont bother as it is just the skeleton name
     $skeleton = $getOpt_optValue;
   }
   else {
     usage ("Parameter $getOpt_optValue : Will be ignored");
     exit;
   }
 }
}

# ----------------------------------------------------
# -- End of Parameter Section
# ----------------------------------------------------

# establish parameters based on the DBI module selected
if ( $DBIModule eq 'DB2' ) {
  if ( defined($DBIParameter{'DB2INSTANCE'}) ) { $ENV{DB2INSTANCE} = $DBIParameter{'DB2INSTANCE'}; }
}

# calculate some date values
generateDates();

if ( $debugLevel > 0 ) { print STDERR "calling: processSkeleton($skeleton, \"$skelParameters\")\n"; }
my $a = processSkeleton($skeleton, "$skelParameters");
print  "$a\n";

