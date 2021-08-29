#!/usr/bin/perl
# --------------------------------------------------------------------
# runSkeleton.cgi
#
# $Id: runSkeleton.cgi,v 1.15 2021/08/29 13:03:56 db2admin Exp kevin $
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
# Revision 1.15  2021/08/29 13:03:56  db2admin
# allow for parameters entering via $QUERY_STRING
#
# Revision 1.14  2019/09/29 22:43:47  db2admin
# initialise flag values
#
# Revision 1.13  2019/07/16 23:18:35  db2admin
# display SQL when diag level reaches 0
#
# Revision 1.12  2019/06/27 23:49:12  db2admin
# make sure that DBI Parameter is case insensitive
#
# Revision 1.11  2019/06/27 04:51:22  db2admin
# add in 'Input Variable:' parameter
#
# Revision 1.10  2019/05/05 23:23:06  db2admin
# Improve parameter checking
#
# Revision 1.9  2019/01/30 00:20:05  db2admin
# change the parameter names referenced in commonFunctions.pm
#
# Revision 1.8  2018/11/13 00:01:17  db2admin
# make sure the parameters are case insensitive
#
# Revision 1.7  2018/08/08 06:25:05  db2admin
# add in parameter value checking for the dynamic parameters
#
# Revision 1.6  2018/08/07 00:53:51  db2admin
# restructure the way in which the parameter strings are processed
# Add in increment feature for flags
#
# Revision 1.5  2018/08/06 00:37:50  db2admin
# add in flag parameter to the skeleton defined parameters to allow the use of flags rather than parameters
#
# Revision 1.4  2018/06/18 00:43:45  db2admin
# add in option to read configuration from a series of default locations:
# 1. from default.ctl
# 2. from <skeleton stem>.ctl
# 3. from the skeleton file
#
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
use commonFunctions qw(getOpt myDate trim $getOpt_optName $getOpt_optValue @myDate_ReturnDesc $cF_debugLevel $getOpt_web $getOpt_calledBy);
use calculator qw(calcVersion evaluateInfix $calcDebugLevel $calcDebugModules);

# Variables to be used 

my $skeleton;
my $debugLevel;
my $readDefaults ;
my $readSkeleton ;
my %skelParms;             # parameters obtained from the skeleton
my %skelParmsValid;        # what type of validation the parameter needs 
my %skelParmsValue;        # the value of the parameter from the command line
my %parameterIsFlag = ();  # array indicating if a parameter has values or is just a flag
my $parmString;
my $typeOfUse;
my %DBIParameter;
my $extraVariables = '';   # extra supplied variables to be added to the processSkeleton call

#$cf_debugLevel = 0;
$getOpt_calledBy = $0;
my $QUERY_STRING = $ENV{'QUERY_STRING'};
if ( $QUERY_STRING ne '' ) { $outputMode = 'HTTP' ; } # if the $QUERY_STRING variable has information it has probably come from the web 

# Usage subroutine

my $ID = '$Id: runSkeleton.cgi,v 1.15 2021/08/29 13:03:56 db2admin Exp kevin $';
my @V = split(/ /,$ID);
my $Version=$V[2];
my $Changed="$V[3] $V[4]";

sub usage {

  # display a usage message and an error message (if supplied)

  if ( $#_ > -1 ) {
    if ( trim("$_[0]") ne "" ) {
      print STDERR "\n$_[0]\n\n";
    }
  }

  my $nl = "<BR>";

  if ( $outputMode ne "HTTP" ) {
    $nl = "";
  }

  print STDERR "Usage: $0 <skeleton> -?hs [-x | -X] [-v[v]] [-S] [other parameters as dictated by the skeleton] $nl
  $nl
       Version $Version Last Changed on $Changed (UTC)  $nl
  $nl
       -h or -?           : This help message  $nl
       -s                 : Silent mode (limit displayed output)  $nl
       -S                 : ignores the skeleton parameter and writes all output to STDOUT $nl
       -x                 : Do NOT read defaults from default.ctl or <skeleton>.ctli (ONLY read from the skeleton file)
       -X                 : Do NOT read defaults from the skeleton file (ONLY read from the .ctl file - default and skelname)
       -v                 : set debug level  $nl
       <skeleton>         : the skeleton to be processed $nl
       [other parameters] : parameters as specified on \"Input Parameter\" statements in the skeleton $nl
  $nl
       This script will generate output based on the instructions detailed in the passed skeleton $nl
  $nl
       NOTE: The skeleton name MUST appear before all other parameters but the order of all other $nl
             parameters is generally not important $nl
             if -x and -X are set then no run time parameters will be read from files
  $nl ";
}

my $today;           # today's date in YYYMMDD format
my $yesterday_date;  # yesterday's date in YYYY-MM-DD format

sub checkDate {
  # ------------------------------------------------------------------------------
  # Check thatthe supplied string matches the date mask
  #
  # Valid masks are:
  #
  #     YYYYMMDD 
  #     YYYY.MM.DD    - the . can be any character but will be modified to - on return
  #     YYMMDD
  #     YY.MM.DD      - the . can be any character but will be modified to - on return
  #     DDMMYY
  #     DD.MM.YY      - the . can be any character but will be modified to - on return
  #
  # Returns blank if there is no match or adjusted date if it is valid
  # ------------------------------------------------------------------------------

  my $mask = uc(shift);
  my $testString = shift;
  my $yr;
  my $mn;
  my $dy;

  if ( length($mask) != length($testString) ) { # the lengths must be identical in length
    return '';
  }
  
  if ( 'YYMMDD DDMMYY YY.MM.DD DD.MM.YY' =~ $mask ) { # short form year check
    if ( $mask eq 'YYMMDD' ) { ($yr,$mn,$dy) = ( $testString =~ /(..)(..)(..)/ ) ; }
    elsif ( $mask eq 'YY.MM.DD' ) { ($yr,$mn,$dy) = ( $testString =~ /(..).(..).(..)/ ) ; }
    elsif ( $mask eq 'DDMMYY' ) { ($dy,$mn,$yr) = ( $testString =~ /(..)(..)(..)/ ) ; }
    elsif ( $mask eq 'DD.MM.YY' ) { ($dy,$mn,$yr) = ( $testString =~ /(..).(..).(..)/ ) ; }

    # do the tests ....

    my @dateReturn = myDate("Date:20$yr$mn$dy");
    if ( $dateReturn[12] ne '' ) { # there was an issue .....
      print STDERR "$dateReturn[12]\n";
      return '';
    }
    else {
      if ( length($mask) == 6 ) { # no separators so just send back the original string
        return $testString;
      }
      else {
        if ( substr($mask,0,2) eq 'YY' ) {
          return "$yr-$mn-$dy";
        }
        else {
          return "$dy-$mn-$yr";
        }
      }
    }
  }
  elsif ( 'YYYYMMDD DDMMYYYY YYYY.MM.DD DD.MM.YYYY' =~ $mask ) { # long form year check
    if ( $mask eq 'YYYYMMDD' ) { ($yr,$mn,$dy) = ( $testString =~ /(....)(..)(..)/ ) ; }
    elsif ( $mask eq 'YYYY.MM.DD' ) { ($yr,$mn,$dy) = ( $testString =~ /(....).(..).(..)/ ) ; }
    elsif ( $mask eq 'DDMMYYYY' ) { ($dy,$mn,$yr) = ( $testString =~ /(..)(..)(....)/ ) ; }
    elsif ( $mask eq 'DD.MM.YYYY' ) { ($dy,$mn,$yr) = ( $testString =~ /(..).(..).(....)/ ) ; }

    # do the tests ....

    my @dateReturn = myDate("Date:$yr$mn$dy");
    if ( $dateReturn[12] ne '' ) { # there was an issue .....
      print STDERR "$dateReturn[12]\n";
      return '';
    }
    else {
      if ( length($mask) == 8 ) { # no separators so just send back the original string
        return $testString;
      }
      else {
        if ( substr($mask,0,2) eq 'YY' ) {
          return "$yr-$mn-$dy";
        }
        else {
          return "$dy-$mn-$yr";
        }
      }
    }
  }

}

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

sub setSkelOptions {

  # Gather the skeleton options from the supplied file handle

  my $fileHandle = shift; 
  my $file = shift; 

  while (<$fileHandle>) {
    if ( $_ =~ /End.*Control Information/i ) { last; } # indicates that no further control information in file so finish
    if ( uc(substr($_,0,3)) eq ")CM" ) { # it is a comment so may be a driver parameter
      if ( $_ =~ /Input Parameter/i ) { # input parameter ....
        my ($prm, $var, $valid) = ( $_ =~ /[Rr]: \((.*)\)\s*(\S*)\s*(\S*)/ );
		# check to make sure that the parm hasn't already been defined
        if ( $parmString =~ /$prm/ ) { 
          if ( defined($skelParms{$prm}) ) { # parameter already set within the control cards
            print STDERR "Parameter $prm [from file] already in use - duplicated parameter - it will be overridden\nOLD: $skelParms{$prm} NEW: $var\n"; 
          }
          else {
            print STDERR "Parameter $prm [from file] already in use - duplicated parameter - it will be ignored as this is one of the reserved parms (h?sSvVxX)\n"; 
          }
        }		
        $parmString .= "$prm:";
        $skelParms{$prm} = $var;
        $skelParmsValid{$prm} = $valid;
        if ( $debugLevel > 0 ) { print STDERR "From File ($file): Parm $prm read in and assigned to $var\n"; }
      }
      elsif ( $_ =~ /Input Flag/i ) { # input flag .... sets a boolean value
        # of the form: Input Flag: (v) debugLevel
        my ($prm, $var, $valid) = ( $_ =~ /[gG]: *\((.*)\)\s*(\S*)\s*(\S*)/ );
        if ( $var eq '' ) { print "Format of the parameter should be : 'Input Flag: (v) debugLevel validation'\n"; }
        else {
		  # check to make sure that the parm hasn't already been defined
          if ( $parmString =~ /$prm/ ) { 
            if ( defined($skelParms{$prm}) ) { # parameter already set within the control cards
              print STDERR "Parameter $prm [from file] already in use - duplicated parameter - it will be overridden\nOLD: $skelParms{$prm} NEW: $var\n"; 
            }
            else {
              print STDERR "Parameter $prm [from file] already in use - duplicated parameter - it will be ignored as this is one of the reserved parms (h?sSvVxX)\n"; 
            }
          }		  
          $parmString .= "$prm";
          $skelParms{$prm} = $var;
          $skelParmsValid{$prm} = $valid;
          $skelParmsValue{$prm} = 0; # init flag
          $parameterIsFlag{$prm} = 1;
          if ( $debugLevel > 0 ) { print STDERR "From File ($file): Flag $prm read in and assigned to $var\n"; }
        }
      }
      elsif ( $_ =~ /Input Variable/i ) { # input variable .... sets a variable value
        # of the form: Input Variable: variable value
        my ($var, $val) = ( $_ =~ /[eE]: *([\S]*)\s*(.*)/ );
        if ( $var eq '' ) { print "Format of the parameter should be : 'Input Parameter: variable value'\n"; }
        else {
          if ( $extraVariables eq '' ) {
            $extraVariables = "$var=$val";
          }
          else {
            $extraVariables .= ",$var=$val";
          }
          if ( $debugLevel > 0 ) { print STDERR "From File ($file): Variable $var has had $val assigned\n"; }
        }
      }
      elsif ( $_ =~ /Type of use/i ) { # type of output
        my ($tou) = ( $_ =~ /[eE]:\s*(\S*)/ );
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
        if ( $debugLevel > 0 ) { print STDERR "From File ($file): Type of use is $typeOfUse\n"; }
      }
      elsif ( $_ =~ /Requires DBI/i ) { # type of output
        my ($DBIPrm) = ( $_ =~ /[iI]:\s*(\S*)/ );
        if ( defined($DBIPrm) ) { # DBI required
          $DBIModule = $DBIPrm;
        }
        if ( $debugLevel > 0 ) { print STDERR "From File ($file): DBI Module required: $DBIModule\n";  }
      }
      elsif ( $_ =~ /DBI Parameter/i ) { # type of output
        my ($prm, $var) = ( $_ =~ /[rR]: \((.*)\)\s*(\S*)/ );
        $DBIParameter{$prm} = $var;
        if ( $debugLevel > 0 ) { print STDERR "From File ($file): DBI Parm $var read in and assigned to $prm\n"; }
      }
    }
  }
} # end of setSkelOptions

# before it goes too far check to see what is in the skeleton (and check that a valid skeleton has been passed)

if ( ($#ARGV == -1) && ( $QUERY_STRING eq '') ) { # MUST have at least 1 parameter
  usage("this script requires at least 1 parameter that points to an existing skeleton file($QUERY_STRING)");
  exit;
}

my $confFile;

# save the skeleton name
if ( $QUERY_STRING != '' ) {
  $QUERY_STRING =~ s/\+/ /g;
  $QUERY_STRING =~ s/\&/ /g;
  my @bits = split(" ",$QUERY_STRING);
  $skeleton = $bits[0];
}
else {  
  $skeleton = $ARGV[0];
}
$debugLevel = 0;
$readDefaults = 1;
$readSkeleton = 1;
# do a quick check to see if debug mode or ignore defaults will be set later
for ( my $i = 0 ; $i <= $#ARGV ; $i++ ) { 
  if ( $ARGV[$i] =~ /^-.*v/ ) { $debugLevel = 1 ; } # a debug parameter is set
  if ( $ARGV[$i] =~ /^-.*x/ ) { $readDefaults = 0 ; } # dont read defaults is set
  if ( $ARGV[$i] =~ /^-.*X/ ) { $readSkeleton = 0 ; } # dont read defaults is set
}
%skelParms = ();
%skelParmsValid = ();
%skelParmsValue = ();
$parmString = ":h?sSvV:xX";
$typeOfUse = 'STDOUT';
$DBIModule = '';
%DBIParameter = ();
my $stem = $skeleton;
$stem =~ s/\..*?$//g ; 

if ( $readDefaults ) { # look for default config files and initialise with the values found there
  if ( -f "default.ctl" ) { # file exists .....
    if ( ! open( $confFile, "<", "default.ctl" ) ) { # unable to read file 
      my $lastcc = $!;
      usage("Unable to open file $ARGV[0]\nError: $lastcc\n");
      exit;
    }
    setSkelOptions($confFile, "default.ctl") ;
    close $confFile;
  }
  if ( -f "$stem.ctl" ) { # file exists .....
    if ( ! open( $confFile, "<", "$stem.ctl" ) ) { # unable to read file 
      my $lastcc = $!;
      usage("Unable to open file $ARGV[0]\nError: $lastcc\n");
      exit;
    }
    setSkelOptions($confFile, "$stem.ctl") ;
    close $confFile;
  }
}

if ( $readSkeleton ) { # look for config initialisation values in the skeleton
  if ( ! open( $confFile, "<", $ARGV[0] ) ) { # file not able to be read
    my $lastcc = $!;
    usage("Unable to open file $ARGV[0]\nError: $lastcc\n");
    exit;
  }

  setSkelOptions($confFile, $skeleton) ;

  close $confFile;
}

if ( $debugLevel > 0 ) { print STDERR "Parameter string : $parmString\n"; }

if ( $outputMode eq 'HTTP' ) {
  print "Content-type: text/html\r\n\r\n";
}

if ( $outputMode eq 'HTTPDL' ) { $outputMode = 'HTTP'; }

# Set parameter defaults

$debugLevel = 0;
my $silent = "No";
my $skelParameters = $extraVariables;
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
   usage ("xxxxxxxxxxxxxxx");
   exit;
 }
 elsif ( $getOpt_optName eq "s" )  {
   $silent = "Yes";
 }
 elsif ( $getOpt_optName eq "x" )  {
   $readDefaults = 0;
   if ( $silent ne "Yes" ) { print STDERR "Defaults will not be read from default file (default.ctl) or the skeleton ctl file ($stem.ctl)\n"; }
 }
 elsif ( $getOpt_optName eq "X" )  {
   $readSkeleton = 0;
   if ( $silent ne "Yes" ) { print STDERR "Defaults config will not be read from the skeleton file ($skeleton)\n"; }
 }
 elsif ( $getOpt_optName eq "S" )  {
   $outputMode = 'STDOUT';
   if ( $silent ne "Yes" ) { print STDERR "Output will be formatted for a terminal\n"; }
 }
 elsif ( $getOpt_optName eq "v" )  { # debug option set
   $skelDebugLevel++;
   $calcDebugLevel++;
   $debugLevel++;
   if ( $skelDebugLevel == 0) { # only set the parameter once
     if ( $skelParameters eq '' ) { 
       $skelParameters = 'SKL_SHOWSQL=YES';
     }
     else {
       $skelParameters .= ',SKL_SHOWSQL=YES';
     }
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
   if ( defined($parameterIsFlag{$getOpt_optName}) ) { # parameter was defined as a flag ( so just boolean)
     if ( uc($skelParmsValid{$getOpt_optName}) eq 'ADD' ) { # increment the current value
       if ( defined($skelParmsValue{$getOpt_optName}) ) { # the value exists (and so should be 1
         $skelParmsValue{$getOpt_optName}++;
       }
       else { # need to define the first time
         $skelParmsValue{$getOpt_optName} = 1;
       }
     }
     else { # it isn't add so just set it to 1
       $skelParmsValue{$getOpt_optName} = 1;
     }
   }
   else { # it is not a flag so just store the parameter
     if ( ($skelParmsValid{$getOpt_optName}) eq  'NUM' ) { # check to make sure the parm is numeric
       if ( ($getOpt_optValue * 1) != $getOpt_optValue ) { # mustn't be a numeric!
         usage ("Value for $getOpt_optName MUST be numeric (value=$getOpt_optValue)");
         exit;
       }
       else {
         $skelParmsValue{$getOpt_optName} = $getOpt_optValue;
       }
     }
     elsif ( ($skelParmsValid{$getOpt_optName} ne '' ) && (" YYMMDD DDMMYY YY.MM.DD DD.MM.YY YYYYMMDD DDMMYYYY YYYY.MM.DD DD.MM.YYYY " =~ uc($skelParmsValid{$getOpt_optName})) ) { # check to make sure the parm is a date
       $getOpt_optValue = checkDate(uc($skelParmsValid{$getOpt_optName}), $getOpt_optValue);
       if ( $getOpt_optValue eq '' ) { # failed check
         usage ("Value for $getOpt_optName MUST be in the format " . uc($skelParmsValid{$getOpt_optName}) . " - it was $getOpt_optValue");
         exit;
       }
       else {
         $skelParmsValue{$getOpt_optName} = $getOpt_optValue;
       }
     }
     else { # no recognised test to do
       $skelParmsValue{$getOpt_optName} = $getOpt_optValue;
     }
   }
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

# flesh out the skelParameters with dynamically created parameters


foreach my $key (keys %skelParmsValue) {
  if ( $skelParameters eq '' ) {
    $skelParameters = "$skelParms{$key}=$skelParmsValue{$key}";
  }
  else {
    $skelParameters .= ",$skelParms{$key}=$skelParmsValue{$key}";
  }
}
if ( $debugLevel > 0 ) { print STDERR "Skeleton Parameter: $skelParameters\n"; }

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
print "$a\n";



