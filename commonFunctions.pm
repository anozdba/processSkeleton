#!/usr/bin/perl
# --------------------------------------------------------------------
# commonFunctions.pm
#
# $Id: commonFunctions.pm,v 1.37 2019/02/01 00:59:27 db2admin Exp db2admin $
#
# Description:
# Package cotaining common code.
#   Subroutines included:
#     displayMinutes 
#     getCurrentTimestamp 
#     timeAdd 
#     timeAdj
#     timeDiff 
#     commonVersion 
#     getOpt 
#     getOpt_form 
#     trim 
#     ltrim 
#     rtrim
#     isValidDate
#     myDate 
#     processDirectory 
#     localDateTime 
#     convertToTimestamp 
#
# Usage:
#   trim()
#     $x = trim($y) # strip blanks from the start and end of a string
#
#   timeAdj(TS,minutes)
#     $x = timeAdj('2016.09.19 08:05:01','-15')   # returns a value of '2016.09.19 07:50:01'
#
#   ltrim()
#     $x = ltrim($y) # strip blanks from the start of a string
#
#   rtrim()
#     $x = rtrim($y) # strip blanks from the end of a string
#
#   myDate()
#     Usage: myDate [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]
#         and it will return an array containg the following elements:
#              $DD,$MM,$YY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW
#
#              i.e. a call of 
#
#                  @dateReturn = myDate('Date:20140728');
#                  for (my $i=0; $i <= $#dateReturn; $i++) {
#                    print "Returned Value for $myDate_ReturnDesc[$i] is: $dateReturn[$i]\n";
#                  }
#
#                  Returned Value for Day of Month is: 28
#                  Returned Value for Month is: 07
#                  Returned Value for Year is: 2014
#                  Returned Value for Day Suffix is: th
#                  Returned Value for Month Name is: July
#                  Returned Value for Number of days since Base Date is: 18105
#                  Returned Value for Base Date is: 1965
#                  Returned Value for EOM is: N
#                  Returned Value for EOY is: N
#                  Returned Value for EOFY is: N
#                  Returned Value for BOM is: N
#                  Returned Value for Day of Week is: MON
#                  Returned Value for Message is:
#
#                  Note the availability of the return value description array @myDate_ReturnDesc
# 
#     It can also be used to identify a date x days from a set base year. So to 
#     work out what day Julian date 10200 is we could use the function as :
#
#              @dateReturn = myDate("200 BASE:2014")
#              for (my $i=0; $i <= $#dateReturn; $i++) {
#                print "Returned Value for $myDate_ReturnDesc[$i] is: $dateReturn[$i]\n";
#              }
#
#              Returned Value for Day of Month is: 19
#              Returned Value for Month is: 07
#              Returned Value for Year is: 2014
#              Returned Value for Day Suffix is: th
#              Returned Value for Month Name is: July
#              Returned Value for Number of days since Base Date is: 200
#              Returned Value for Base Date is: 2014
#              Returned Value for EOM is: N
#              Returned Value for EOY is: N
#              Returned Value for EOFY is: N
#              Returned Value for BOM is: N
#              Returned Value for Day of Week is: SAT
#              Returned Value for Message is:
# 
#     As well it can be used to identify the number of days between 2 date by processing 
#     each date and then substracting their $T[5] elements.
#
#   getOpt()
#  
#   A standard use of getOpt would look like:
#
#   # Set up the environment to include the commonFunctions module ...
#
#     BEGIN {
#       if ( $^O eq "MSWin32") {
#         print "Windows is running ...\n";
#         $machine = `hostname`;
#         $OS = "Windows";
#         $scriptDir = 'c:\udbdba\scrxipts';
#         $tmp = rindex($0,'\\');
#         if ($tmp > -1) {
#           $scriptDir = substr($0,0,$tmp+1)  ;
#         }
#       }
#       else {
#         print "$^O is running ...\n";
#         $machine = `uname -n`;
#         $machine_info = `uname -a`;
#         @mach_info = split(/\s+/,$machine_info);
#         $OS = $mach_info[0] . " " . $mach_info[2];
#         $scriptDir = "scripts";
#         $tmp = rindex($0,'/');
#         if ($tmp > -1) {
#           $scriptDir = substr($0,0,$tmp+1)  ;
#         }
#       }
#     }
#      
#     use lib "$scriptDir";
#      
#     use commonFunctions qw(getOpt myDate trim $getOpt_optName $getOpt_optValue @myDate_ReturnDesc);
#
#     # Set default values for variables
#
#     $silent = "No";
#
#     # ----------------------------------------------------
#     # -- Start of Parameter Section
#     # ----------------------------------------------------
#
#     # Initialise vars for getOpt ....
#
#     $opt = ":?hsvtT:S:d:w";    # set up the valid parm values
#
#     while ( getOpt($opt) ) {
#       if (($getOpt_optName eq "h") || ($getOpt_optName eq "?") )  {
#         usage ("");   # call the usage routine display help
#         exit;
#       }
#       elsif (($getOpt_optName eq "s") )  { # turn on silent
#         $silent = "Yes";
#       }
#       elsif (($getOpt_optName eq "v"))  {  # set debug Level
#         $debugLevel++;
#         if ( $silent ne "Yes") {
#           print STDERR "Debug level now set to $debugLevel\n";
#         }
#       }
#       .
#       ..... insert other parameter option activities here
#       .
#       elsif ( $getOpt_optName eq ":" ) {
#         usage ("Parameter $getOpt_optValue requires a parameter");
#         exit;
#       }
#       else { # handle other entered values ....
#         if ( $parameter eq "" ) { # assume parameters if nothing is indicated
#           $directory = $getOpt_optValue;
#           if ( $silent ne "Yes") {
#             print STDERR "Directory $getOpt_optValue will be processed\n";
#           }
#         }
#         else {
#           usage ("Parameter $getOpt_optValue is invalid");
#           exit;
#         }
#       }
#     }
#
#     # ----------------------------------------------------
#     # -- End of Parameter Section
#     # ----------------------------------------------------
#
# $Name:  $
#
# ChangeLog:
# $Log: commonFunctions.pm,v $
# Revision 1.37  2019/02/01 00:59:27  db2admin
# change all printDebug to displayDebug for consistency
#
# Revision 1.36  2019/01/29 23:22:00  db2admin
# 1. ensure that the test routines always print their debug information
# 2. add in debug information in durationDays
#
# Revision 1.35  2019/01/29 22:53:34  db2admin
# 1. standardise debug printing
# 2. add in durationDays function to calculate the number of days in a given day month year duration
# 3. modify processDuration to actually do the work (rather than be a stub)
# 4. add in isNumeric function
# 5. correct convertDurationToTimestamp code
# 6. Add in testCommonFunctions routine that will drive tests across a number of routines
# 7. Add in getDate routine to return the current date in a selected format
#
# Revision 1.33  2019/01/24 02:50:04  db2admin
# add in isValidTimestamp function
#
# Revision 1.32  2019/01/23 04:42:40  db2admin
# add in isValidDate routine
#
# Revision 1.31  2018/12/27 21:46:26  db2admin
# 1. Alter the allowable timestamp formats
# 2. correct some comments
#
# Revision 1.30  2018/10/15 05:01:01  db2admin
# add in getCurrentTimestamp routine
#
# Revision 1.29  2018/05/29 04:30:48  db2admin
# add in processing to cope with web supplied string parameters containing spaces
#
# Revision 1.28  2018/04/03 06:14:13  db2admin
# adjust getOpt routine to enforce hyphen identification of parameter names where specified
# .
#
# Revision 1.27  2018/03/21 05:27:32  db2admin
# Correct bug in processing of extended parameters (starting with --)
# Allow partial entry of parameter names for extended parameters
#
# Revision 1.26  2018/02/13 23:50:16  db2admin
# ensure that parameters to timeAdj and displayMinutes are integers
#
# Revision 1.25  2018/02/13 23:28:38  db2admin
# replace with working version from another machine
#
# Revision 1.23  2018/02/13 23:13:44  db2admin
# correct issue of non whole hours being returned from displayMinutes when less than 1 day run time
#
# Revision 1.22  2017/12/06 21:42:53  db2admin
# add in timeAdj function
#
# Revision 1.21  2017/09/25 04:32:31  db2admin
# add in convertToTimestamp function
#
# Revision 1.20  2017/04/24 02:14:43  db2admin
# change default for datediff to minutes difference
#
# Revision 1.19  2017/04/10 03:03:37  db2admin
# moved an upper case conversion to hopefully not reset the defiend flag
#
# Revision 1.18  2017/02/28 04:56:24  db2admin
# add new parameter to timeDiff to allowing varying return units of measure
#
# Revision 1.17  2016/11/28 23:51:54  db2admin
# modify getOpt to ignore passed parameters that are null
#
# Revision 1.16  2016/09/19 05:25:39  db2admin
# Added in new callable routines displayMinutes timeDiff timeAdd
#
# Revision 1.15  2016/08/25 06:29:50  db2admin
# improve debugging messages
# correct bug in script when script called multiple times
#
# Revision 1.14  2016/07/01 01:26:46  db2admin
# always process web parameters if they are there and if no line parameters are entered
#
# Revision 1.13  2016/06/03 05:24:29  db2admin
# correct processing of web parameters
#
# Revision 1.12  2015/11/11 22:03:54  db2admin
# remove webserer added characters from getOpt_form processing
#
# Revision 1.11  2015/11/03 23:17:51  db2admin
# alter parm separators (exclude + as it is used as a space replacement in a POST request)
#
# Revision 1.10  2015/11/02 06:24:25  db2admin
# Add in new functions processDirectory and localDateTime
#
# Revision 1.9  2015/10/25 21:16:28  db2admin
# add in option to remove escape characters from string returned by getOpt
#
# Revision 1.7  2015/10/21 00:28:41  db2admin
# add in code to manage variables to getOpt_form supplied via POST
#
# Revision 1.5  2015/10/20 22:31:15  db2admin
# add in new getOpt_form function
#
# Revision 1.4  2015/07/29 00:24:08  db2admin
# Add in new functionality to process parameters passed through QUERY_STRING variable (CGI 'GET' POST)
# Correct bug in checking parameter numbers
# Add in more diagnostic capability
# Add in new variables getOpt_debugLevel and getOpt_calledBy to improve diagnostics
# Modified error printing to go to STDERR (which then goes to apache2 log)
#
#
# Revision 1.3  2015/03/13 02:42:53  db2admin
# 1. Correct date generation for offset dates when multiple calls are made to the routine
# 2. Improve debugging output
#
# Revision 1.2  2014/08/04 04:51:52  db2admin
# Add in documentation
# Correct bug in myDate (day was wrong if base date was changed)
# NOTE: myDate doesn't function for dates before 1st Jan 1965
#
#
# --------------------------------------------------------------------

package commonFunctions;

use strict;

# export parameters ....
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(trim ltrim rtrim commonVersion getOpt isValidDate isValidTimestamp myDate $getOpt_web $getOpt_optName $getOpt_min_match $getOpt_optValue getOpt_form @myDate_ReturnDesc $cF_debugLevel $getOpt_calledBy $parmSeparators processDirectory $maxDepth $fileCnt $dirCnt localDateTime displayMinutes timeDiff timeAdd timeAdj convertToTimestamp getCurrentTimestamp testCommonFunctions $cF_debugModules processDuration);

# persistent variables

# processDircetory

our $maxDepth;        # maximum directory levels to descend in the tree
our $fileCnt;         # number of files encountered
our $dirCnt;          # number of directories encounterd (not including . and ..

my @PARGV;
my @QPARGV;
my $getOpt_prm;
my $getOpt_prm_flag;
our $getOpt_optName;         # contains the option currently being processed
our $getOpt_optValue;        # contains the value of the option currently being processed
our $getOpt_web;             # indicates that the result is for the web
our $getOpt_calledBy;        # indicates the routine calling the module
our $getOpt_min_match = 2;   # minimum number of characters required for a parameter match (-1 => whole parameter equal)
our $parmSeparators = ' &';  # string contains characters to be used as separators in getOpt_form
my @monthName;
my %monthNumber;
my @monthDays;
our @myDate_ReturnDesc = ('Day of Month', 'Month', 'Year', 'Day Suffix', 'Month Name', 'Number of days since Base Date','Base Date', 'EOM','EOY','EOFY','BOM','Day of Week','Message');
our $cF_debugLevel ;
our $cF_debugModules; # when set indiactes which modules to print debug messages for
my %getOpt_valid_parms;
my $search_valid_parms = '';
my %getOpt_caseinsens;   # 0 => case sensitive, 1 => case insensitive
my %getOpt_requiresDash;

BEGIN {
  $getOpt_prm = 0;
  $getOpt_optName = "";
  $getOpt_optValue = "";
  $getOpt_calledBy = "unknown module";
  $monthName[1] = "January";
  $monthDays[1] = "31";
  $monthName[2] = "February";
  $monthDays[2] = "28";
  $monthName[3] = "March";
  $monthDays[3] = "31";
  $monthName[4] = "April";
  $monthDays[4] = "30";
  $monthName[5] = "May";
  $monthDays[5] = "31";
  $monthName[6] = "June";
  $monthDays[6] = "30";
  $monthName[7] = "July";
  $monthDays[7] = "31";
  $monthName[8] = "August";
  $monthDays[8] = "31";
  $monthName[9] = "September";
  $monthDays[9] = "30";
  $monthName[10] = "October";
  $monthDays[10] = "31";
  $monthName[11] = "November";
  $monthDays[11] = "30";
  $monthName[12] = "December";
  $monthDays[12] = "31";
  %monthNumber = ( 'Jan' =>  '01', 'Feb' =>  '02', 'Mar' =>  '03', 'Apr' =>  '04', 'May' =>  '05', 'Jun' =>  '06',
                    'Jul' =>  '07', 'Aug' =>  '08', 'Sep' =>  '09', 'Oct' =>  '10', 'Nov' =>  '11', 'Dec' =>  '12',
                    'January' =>  '01', 'February' =>  '02', 'March' =>  '03', 'April' =>  '04', 'May' =>  '05', 'June' =>  '06',
                    'July' =>  '07', 'August' =>  '08', 'September' =>  '09', 'October' =>  '10', 'November' =>  '11', 'December' =>  '12' );
  if ( ! defined($cF_debugLevel) ) { $cF_debugLevel = 0; }
  if ( ! defined($cF_debugModules) ) { $cF_debugModules = 'All'; }
  # processDirectory
  $maxDepth = -1;
  $fileCnt = 0;
  $dirCnt = 0;
}

# -----------------------------------------------------------------
# displayMinutes - function to return a supplied minutes value as x days x hours x mins)
#                  (it will not break the days value into years)
#
# Usage: displayMinutes(89);
# Returns: '1 hour 29 minutes'
#
# -----------------------------------------------------------------

sub displayMinutes {

  my $elapsed = shift;
  $elapsed = int($elapsed); # make sure that the number of minutes is an integer
  my $currentRoutine = 'displayMinutes';

  displayDebug( "Total mins: $elapsed", 1, $currentRoutine); 

  if ( $elapsed < 60 ) { return "$elapsed minute" . literalPlural($elapsed); } # under 60 minutes so just return the value

  if ( $elapsed < 1440 ) { # under one day so just return hours and minutes
    my $mins = $elapsed % 60;
    my $hours = int(($elapsed - $mins) / 60);
    return "$hours hour" . literalPlural($hours) . " $mins minute" . literalPlural($mins);
  }

  my $mins = $elapsed % 60;
  my $totalHours = ($elapsed - $mins) / 60;
  my $hours = $totalHours % 24;
  my $days = ($elapsed - (60 * $hours) - $mins)/1440;
  return "$days day" . literalPlural($days) . " $hours hour" . literalPlural($hours) . " $mins minute" . literalPlural($mins);

} # end of displayMinutes

# -----------------------------------------------------------------
# literalPlural - function to return 's' if the parameter is not a 1
# -----------------------------------------------------------------

sub literalPlural {
  my $number = shift;
  if ($number == 1 ) { return ''; } # no s
  else { return 's'; }

} # end of literalPlural

# -----------------------------------------------------------------
# displayDebug - function to print formatted input to STDOUT
#
# usage:    displayDebug('test statement', 'testModule')
#           the parameters are:
#               1. message to be displayed
#               2. debug level when this message should be displayed
#               3. module that is doing the calling
# returns:  'testModule          test statement'  
#
# -----------------------------------------------------------------

sub displayDebug {

  my $test = shift;
  my $level = shift;
  my $routine = shift;

  if ( ( $cF_debugModules eq 'All' ) || ( $routine eq 'testCommonFunctions' ) || ( $routine eq 'testProcessDuration') || ($cF_debugModules =~ /$routine/ ) ) { # check if we are showing messages here

    $routine = substr("$routine                    ",0,20);
    my $TS = getCurrentTimestamp();

    if ( $cF_debugLevel >= $level ) { print STDERR "$routine - $TS - $test\n"; }

  }

} # end of displayDebug

sub getDate {
  # -----------------------------------------------------------
  #  Routine to return a formatted Date in the requested format.
  #
  # Available formats are:
  #    1. YYYY.MM.DD format
  #    2. YYYYMMDD
  #    3. All others YYYY.MM.DD
  #
  # Usage: getDate(2)
  # Returns: YYYYMMDD
  # -----------------------------------------------------------

  my $currentSubroutine = 'getDate';
  
  my $format = shift;
  if ( ! defined($format) ) { $format = 1};
  
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  my $year = 1900 + $yearOffset;
  $month = $month + 1;
  $month = substr("0" . $month, length($month)-1,2);
  my $day = substr("0" . $dayOfMonth, length($dayOfMonth)-1,2);
  
  if ( $format == 2 ) {
    return "$year$month$day";
  }
  else {
    return "$year.$month.$day";
  }
  
} # end of getDate

sub getCurrentTimestamp {
  # -----------------------------------------------------------------
  # getCurrentTimestamp - function to return the current time as a timestamp 
  #
  # usage:    getCurrentTimesatmp()
  # returns:  '2016.09.19 08:20:00'
  #
  # -----------------------------------------------------------------

  my $currentRoutine = 'getCurrentTimestamp';

  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  my $year = 1900 + $yearOffset;
  $month = $month + 1;
  $hour = substr("0" . $hour, length($hour)-1,2);
  $minute = substr("0" . $minute, length($minute)-1,2);
  $second = substr("0" . $second, length($second)-1,2);
  $month = substr("0" . $month, length($month)-1,2);
  my $day = substr("0" . $dayOfMonth, length($dayOfMonth)-1,2);
  return "$year.$month.$day $hour:$minute:$second";

} # end of getCurrentTimestamp

# -----------------------------------------------------------------
# timeAdd - function to return a timestamp with a specified number of
#           minutes added
#
#           timeAdj takes the same parameters but allows a negative value for 
#           the adjustment minutes
# 
#           also timeAdd always returns 00 seconds
#
# usage:    timeAdd('2016.09.19 08:05:01','15')
#           the parameters are:
#               1. timestamp in the format yyyy.mm.dd hh:mm:ss
#               2. elapsed time in minutes
# returns:  '2016.09.19 08:20:00'  
#
# -----------------------------------------------------------------

sub timeAdd {

  my $currentRoutine = 'timeAdd';
  my $startTime = shift;
  my $elapsed = shift;
  my ($year, $mon, $day, $hr, $min, $sec) = ( $startTime =~ /(\d\d\d\d).(\d\d).(\d\d)[ -](\d\d).(\d\d).(\d\d)/ );

  displayDebug( "Timestamp: $startTime (year: $year, month: $mon, day: $day, hour: $hr, min: $min, secs: $sec). Elapsed: $elapsed", 1, $currentRoutine); 

  $min = $min + $elapsed;

  # break the minutes into number of hours and minute remainders
  my $nMin = $min % 60;                         # final minutes past the hour
  displayDebug( "total minutes: $min, new minute: $nMin", 1, $currentRoutine); 
  my $tempHr = (($min - $nMin)/60) + $hr;       # this is the number of hours into the future

  my $nHr = $tempHr % 24;                # Final hour on the day
  $nMin = substr('00' . $nMin, length($nMin), 2); # pad out to 2 digits
  $nHr = substr('00' . $nHr, length($nHr), 2); # pad out to 2 digits
  displayDebug( "total hours: $tempHr, new hour: $nHr", 1, $currentRoutine); 
  my @T = myDate("DATE\:$year$mon$day");   # convert date into number of days from the base date
  my $tempDay = (($tempHr - $nHr)/24) + $T[5]; # days from the base date
  displayDebug( "tempHr: $tempHr, hr: $hr, nHr: $nHr", 1, $currentRoutine);
  my @T1 = myDate($tempDay);                   # convert the number of days back to a gregorian day
  displayDebug( "Base Date Offset: $T[5], New offset: $tempDay, New Date: $T1[2].$T1[1].$T1[0]", 1, $currentRoutine); 

  return "$T1[2].$T1[1].$T1[0] $nHr:$nMin:00";

} # end of timeAdd

# -----------------------------------------------------------------
# timeAdj - function to return a timestamp with a specified number of
#           minutes adjusted
#
# usage:    timeAdd('2016.09.19 08:05:01','15')
#           the parameters are:
#               1. timestamp in the format yyyy.mm.dd hh:mm:ss
#               2. elapsed time in minutes (negative or positive number)
# returns:  '2016.09.19 08:20:01'  
#
# -----------------------------------------------------------------

sub timeAdj {

  my $currentRoutine = 'timeAdj';
  my $startTime = shift;
  my $elapsed = shift;
  $elapsed = int($elapsed); # ensure that the elapsed time is an integer
  my ($year, $mon, $day, $hr, $min, $sec) = ( $startTime =~ /(\d\d\d\d).(\d\d).(\d\d)[ -](\d\d).(\d\d).(\d\d)/ );

  displayDebug( "Timestamp: $startTime (year: $year, month: $mon, day: $day, hour: $hr, min: $min, secs: $sec). Elapsed: $elapsed", 1, $currentRoutine); 
  
  # convert timestamp to number of minutes
  
  my @T = myDate("DATE\:$year$mon$day");   # convert date into number of days from the base date
  my $TS_Minutes = ($T[5] * 1440) + ($hr * 60) + $min;
  displayDebug( "Base Date Offset: $T[5], TS_Minutes: $TS_Minutes", 1, $currentRoutine); 

  # adjust the value 
  $TS_Minutes = $TS_Minutes + $elapsed; # $elapsed may be positive or negative
  displayDebug( "Minutes after adjustment: $TS_Minutes", 1, $currentRoutine); 
  
  # Convert the value back to a timestamp .....
  
  my $new_days = int($TS_Minutes / 1440) ;         # days past the base date
  $TS_Minutes = $TS_Minutes - ( $new_days * 1440); # now holds number of minutes past midnight
  my $new_hours = int($TS_Minutes / 60) ; 
  displayDebug( "New Days Offset: $new_days, Minutes after midnight: $TS_Minutes", 1, $currentRoutine); 
  $new_hours = substr('00' . $new_hours, length($new_hours), 2); # pad out to 2 digits
  $TS_Minutes = $TS_Minutes - ( $new_hours * 60);  # now holds number of minutes past the hour
  $TS_Minutes = substr('00' . $TS_Minutes, length($TS_Minutes), 2); # pad out to 2 digits
  displayDebug( "New Hours Offset: $new_hours, Minutes after the hour: $TS_Minutes", 1, $currentRoutine); 

  # convert the days count back to a gregorian date
  @T = myDate($new_days);   

  displayDebug( "Returned Date: $T[2].$T[1].$T[0] $new_hours:$TS_Minutes:$sec", 1, $currentRoutine); 

  return "$T[2].$T[1].$T[0] $new_hours:$TS_Minutes:$sec";

} # end of timeAdj

# -----------------------------------------------------------------
# timeDiff - function to return the number of minutes between 2 supplied 
#            timestamps
#
# usage:    timeDiff('2016.09.19 08:05:01','2016.09.19 08:20:01'[,'M'])
#           the parameters are:
#               1. timestamp in the format yyyy.mm.dd hh:mm:ss
#               2. timestamp in the format yyyy.mm.dd hh:mm:ss
#               Note: option 3rd parameter S, M, H or D indicating the unit
#                     or measure of the returned value
#                     Timestamp can have any single character between the day/month/year 
#                     Timestamp can have any single character between the hour/min/second 
#                     Timestamp can only have either ' ' or '-' between the data and time 
# returns: the time differences in the unit of measure specified 
#
# -----------------------------------------------------------------

sub timeDiff {

  my $currentRoutine = 'timeDiff';
  my $startTime = shift;
  my $endTime = shift;
  my $UOM = shift;

  if ( ! defined($UOM) ) { $UOM = 'M'; } # when not supplied thedefault is minutes
  $UOM = uc($UOM);

  # start time is formatted yyyy.mm.dd hh:mm:ss

  my ($sYear, $sMon, $sDay, $sHr, $sMin, $sSec) = ( $startTime =~ /(\d\d\d\d).(\d\d).(\d\d)[ -](\d\d).(\d\d).(\d\d)/ );
  my @T = myDate("DATE\:$sYear$sMon$sDay");
  my $startDayOffset = $T[5] ;
  for ( my $j = 0 ; $j <= $#T; $j++) { displayDebug("$j: $T[$j]",2,$currentRoutine); }
  my $startMinsPastMidnight = ($sHr*60) + $sMin;

  # end time is formatted  yyyy.mm.dd hh:mm:ss

  my ($eYear, $eMon, $eDay, $eHr, $eMin, $eSec) = ( $endTime =~ /(\d\d\d\d).(\d\d).(\d\d)[ -](\d\d).(\d\d).(\d\d)/ );
  @T = myDate("DATE\:$eYear$eMon$eDay");
  my $endDayOffset = $T[5] ;
  for ( my $j = 0 ; $j <= $#T; $j++) { displayDebug("$j: $T[$j]",2,$currentRoutine); }
  my $endMinsPastMidnight = ($eHr*60) + $eMin;

  my $daysDiff = $endDayOffset - $startDayOffset;
  my $hrsDiff  = ($daysDiff * 24 ) + $eHr - $sHr;
  my $minsDiff = ($hrsDiff * 60  ) + $eMin - $sMin;
  my $secsDiff = ($minsDiff * 60  ) + $eSec - $sSec;

  displayDebug( "Start Time: $startTime, End Time: $endTime, Mins Diff: $minsDiff", 1, $currentRoutine); 
  displayDebug( "Start Day Offset: $startDayOffset, Start Mins Past Midnight: $startMinsPastMidnight", 2, $currentRoutine); 
  displayDebug( "Start Components: $sYear#$sMon#$sDay#$sHr#$sMin#$sSec", 3, $currentRoutine); 
  displayDebug( "End Day Offset: $endDayOffset, End Mins Past Midnight: $endMinsPastMidnight", 2, $currentRoutine); 
  displayDebug( "End Components: $eYear#$eMon#$eDay#$eHr#$eMin#$eSec", 2, $currentRoutine); 

  if ( $UOM eq 'D' ) { return $daysDiff; }
  elsif ( $UOM eq 'H' ) { return $hrsDiff; }
  elsif ( $UOM eq 'S' ) { return $secsDiff; }
  else  { return $minsDiff; }

} # end of timeDiff

# -----------------------------------------------------------------
# commonVersion - function to return the version onumber of this 
#                 module
# -----------------------------------------------------------------

sub commonVersion {

  my $ID = '$Id: commonFunctions.pm,v 1.37 2019/02/01 00:59:27 db2admin Exp db2admin $';
  my @V = split(/ /,$ID);
  my $nameStr=$V[1];
  (my $name,my $x) = split(",",$nameStr);
  my $Version=$V[2];
  my $Changed="$V[3] $V[4]";

  return "$name ($Version)  Last Changed on $Changed (UTC)";

} # end of commonVersion

sub testDirPrint {

# -----------------------------------------------------------------
# Subroutine to be used with processDirectrory to print directories
#
# Usage : testDirPrint('directory name');
# Returns : prints out directory name
# -----------------------------------------------------------------

  my $currentRoutine = 'testDirPrint';
  my $depth = shift;
  my $dirName = shift;
  
  displayDebug("Dir: $dirName ($depth)",$currentRoutine);
  
} # end of testDirPrint

sub testCommonFunctions {

# -----------------------------------------------------------------
# Subroutine to test the commonFunctions.pm routines
#
# Usage : testCommonFunctions();
# Returns : Test results
# -----------------------------------------------------------------

  my $currentRoutine = 'testCommonFunctions';
  
  displayDebug("Beginning test of commonFunctions.pm",0,$currentRoutine);
  
#     displayMinutes 

  my $res = displayMinutes('89');
  my $expectedRes = '1 hour 29 minutes';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of displayMinutes(89) is : $res", 0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of displayMinutes(89) is : $res , should be '$expectedRes'",0,$currentRoutine);
  }
  
  #     getCurrentTimestamp 

  $res = getCurrentTimestamp();
  displayDebug("All OK - Result of getCurrentTimestamp is : $res",0,$currentRoutine);

#     timeAdd (note timeadd zeroes the seconds)

  $res = timeAdd('2016.09.19 08:05:01','15');
  $expectedRes = '2016.09.19 08:20:00';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of timeAdd('2016.09.19 08:05:01','15') is : $res",0,$currentRoutine);
    displayDebug("NOTE: timeadd zeroes the seconds",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of timeAdd('2016.09.19 08:05:01','15') is : $res , should be '$expectedRes'",0,$currentRoutine);
    displayDebug("NOTE: timeadd zeroes the seconds",0,$currentRoutine);
  }

#     timeAdj

  $res = timeAdj('2016.09.19 08:55:01','15');
  $expectedRes = '2016.09.19 09:10:01';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of timeAdj('2016.09.19 08:55:01','15') is : $res",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of timeAdj('2016.09.19 08:55:01','15') is : $res , should be '$expectedRes'",0,$currentRoutine);
  }

#     timeDiff 

  $res = timeDiff('2016.09.19 08:05:01','2016.09.19 08:20:01','M');
  $expectedRes = '15';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of timeDiff('2016.09.19 08:05:01','2016.09.19 08:20:01','M') is : $res",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of timeDiff('2016.09.19 08:05:01','2016.09.19 08:20:01','M') is : $res , should be '$expectedRes'",0,$currentRoutine);
  }

#     commonVersion 

  $res = commonVersion();
  displayDebug("All OK - Result of commonVersion is : $res",0,$currentRoutine);

#     getOpt 
#     getOpt_form 
#     trim 

  $res = trim('   test  12  ');
  $expectedRes = 'test  12';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of trim('   test  12  ') is : >$res<",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of trim('   test  12  ') is : >$res< , should be '$expectedRes'",0,$currentRoutine);
  }

#     ltrim 

  $res = ltrim('   test  12  ');
  $expectedRes = 'test  12  ';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of ltrim('   test  12  ') is : >$res<",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of ltrim('   test  12  ') is : >$res< , should be '$expectedRes'",0,$currentRoutine);
  }

#     rtrim

  $res = rtrim('   test  12  ');
  $expectedRes = '   test  12';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of rtrim('   test  12  ') is : >$res<",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of rtrim('   test  12  ') is : >$res< , should be '$expectedRes'",0,$currentRoutine);
  }

#     isValidDate
  if ( isValidDate('2019-02-29') ) { # should be FAIL
    displayDebug("Failed - Result of isValidDate('2019-02-29') is : TRUE , should be FALSE",0,$currentRoutine);
  }
  else {  
    displayDebug("All OK - Result of isValidDate('2019-02-29') is : FALSE , should be FALSE",0,$currentRoutine);
  }

  if ( isValidDate('2019-01-29') ) { # should be TRUE
    displayDebug("All OK - Result of isValidDate('2019-01-29') is : TRUE , should be TRUE",0,$currentRoutine);
  }
  else {  
    displayDebug("Failed - Result of isValidDate('2019-01-29') is : FALSE , should be TRUE",0,$currentRoutine);
  }

#     isValidTimestamp
  if ( isValidTimestamp('2019-02-29 01:01:01') ) { # should be FAIL
    displayDebug("Failed - Result of isValidTimestamp('2019-02-29 01:01:01') is : TRUE , should be FALSE",0,$currentRoutine);
  }
  else {  
    displayDebug("All OK - Result of isValidTimestamp('2019-02-29 01:01:01') is : FALSE , should be FALSE",0,$currentRoutine);
  }

  if ( isValidTimestamp('2019-01-29 06:65:09') ) { # should be FALSE
    displayDebug("Failed - Result of isValidTimestamp('2019-01-29 06:65:09') is : TRUE , should be FALSE",0,$currentRoutine);
  }
  else {  
    displayDebug("All OK - Result of isValidTimestamp('2019-01-29 06:65:09') is : FALSE , should be FALSE",0,$currentRoutine);
  }

  if ( isValidTimestamp('2019-01-29 06:05:09') ) { # should be TRUE
    displayDebug("All OK - Result of isValidTimestamp('2019-01-29 06:05:09') is : TRUE , should be TRUE",0,$currentRoutine);
  }
  else {  
    displayDebug("Failed - Result of isValidTimestamp('2019-01-29 06:05:09') is : FALSE , should be TRUE",0,$currentRoutine);
  }

#     myDate 
  my @resArray = myDate(678);
  $res = "$resArray[11] $resArray[0]$resArray[3] $resArray[4], $resArray[2] - $resArray[7]$resArray[8]$resArray[9]$resArray[10] - ($resArray[2]/$resArray[1]/$resArray[0])";
  $expectedRes = "THU 09th November, 1966 - NNNN - (1966/11/09)";
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of myDate(678) is : $res",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of myDate(678) is : $res , should be '$expectedRes'",0,$currentRoutine);
  }

  @resArray = myDate("DATE\:20170630");
  $res = "$resArray[11] $resArray[0]$resArray[3] $resArray[4], $resArray[2] - $resArray[5] - $resArray[7]$resArray[8]$resArray[9]$resArray[10] - ($resArray[2]/$resArray[1]/$resArray[0])";
  $expectedRes = "FRI 30th June, 2017 - 19173 - YNYN - (2017/06/30)";
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of myDate(\"DATE\:20170630\") is : $res",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of myDate(\"DATE\:20170630\") is : $res , should be '$expectedRes'",0,$currentRoutine);
  }

# processDirectory

#  displayDebug("Testing processDirectory ...",$currentRoutine);
#  processDirectory('.',3,&testDirPrint);
  
#     localDateTime 

#     convertToTimestamp 

  $res = convertToTimestamp('Sep 17, 2017 6:00:07 PM');
  $expectedRes = '2017.09.17 18:00:07';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of convertToTimestamp('Sep 17, 2017 6:00:07 PM') is : $res",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of convertToTimestamp('Sep 17, 2017 6:00:07 PM') is : $res , should be '$expectedRes'",0,$currentRoutine);
  }
  
  # convertDurationToTimestamp

  $res = convertDurationToTimestamp('51196','M');
  $expectedRes = '0000-00-35 13.16.00';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of convertDurationToTimestamp('51196','M') is : $res",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of convertDurationToTimestamp('51196','M') is : $res , should be '$expectedRes'",0,$currentRoutine);
  }
  
  $res = convertDurationToTimestamp('3071766','S');
  $expectedRes = '0000-00-35 13.16.06';
  if ( $res eq $expectedRes ) {
    displayDebug("All OK - Result of convertDurationToTimestamp('3071766','S') is : $res",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of convertDurationToTimestamp('3071766','S') is : $res , should be '$expectedRes'",0,$currentRoutine);
  }
  
  # durationDays
  
  $res = durationDays('03', '02', '01');
  displayDebug("Will display the number of days 3 days, 2 months and 1 year into the future - will be around 428 depending on the month/year in which it is run",0,$currentRoutine);
  displayDebug("All OK - Result of durationDays('03', '02', '01') is : $res",0,$currentRoutine);

  # processDuration
 
  testProcessDuration('1 day 2 minutes', 'M', '1442', 1);
  testProcessDuration('1 day 2 minutes 1 year', 'M', '527042', 1);
  testProcessDuration('1 day 2 minutes', 'S', '86520', 1);
  testProcessDuration('1 day 2 minutes 2 years', 'D', '732', 1);
  testProcessDuration('1 day 2 minutes 2 years', 'T', '0002-00-1 00.02.00', 1);
  testProcessDuration('1 2 minutes 2 years', 'D', '1 2 minutes 2 years',0 );
  
  displayDebug("Finished test of commonFunctions.pm",0,$currentRoutine);
  
} # end of testCommonFunctions

sub testProcessDuration {
  # -----------------------------------------------------------------
  # Subroutine to test the processDuration call
  # -----------------------------------------------------------------

  my $duration = shift;
  my $unit = shift;
  my $result = shift; 
  my $isOK = shift; 

  my $currentRoutine = 'testProcessDuration';

  my ($isDuration, $resDuration) = processDuration($duration, $unit);
  if ( $resDuration eq $result ) {
    displayDebug("    OK - Result of processDuration('$duration', '$unit') is : $resDuration",0,$currentRoutine);
  }
  else {
    displayDebug("Failed - Result of processDuration('$duration', '$unit') is : $resDuration, should be $result",0,$currentRoutine);
  }

  if ( $isDuration == $isOK ) {
    if ( $isDuration ) {
      displayDebug("    OK - Result was correctly identified as a valid duration",0,$currentRoutine);
    }
    else {
      displayDebug("    OK - Result was correctly identified as an invalid duration",0,$currentRoutine);
    }
  }
  else {
    if ( $isDuration ) {
      displayDebug("Failed - Result was incorrectly identified as a valid duration",0,$currentRoutine);
    }
    else {
      displayDebug("Failed - Result was incorrectly identified as an invalid duration",0,$currentRoutine);
    }
  }
  
} # end of testProcessDuration

sub setParameterIfNecessary {
  # -----------------------------------------------------------------
  # setParameterIfNecessary - set the parameter if necessary and
  # otherwise just sets it to space
  # -----------------------------------------------------------------
  
  my $getOpt_prmName = shift;
  my $webParmSet = shift;
  my $origName = shift;    # if it was a partial match then this was the original parameter name

  if ( $getOpt_valid_parms{$getOpt_prmName} eq ":" ) {     # is a parameter required?
    if ( $webParmSet ne "" ) {                              # getOpt_web set and a parm has already been found
      $getOpt_optName = $getOpt_prmName;                   # set the returned option name
      $getOpt_optValue = $webParmSet;                       # set the returned parameter
      $getOpt_prm_flag = "Y";
    }
    else { # normal space delimited parameters
      $getOpt_optName = $getOpt_prmName;                     # set the option name
      if ( defined($PARGV[$getOpt_prm+1] ) ) {                # there is another parm
        if ( substr($PARGV[$getOpt_prm+1],0,1) eq "-" ) {     # check to see if it is another parameter
          $getOpt_optValue = $getOpt_prmName;                # Pass back the option name as the parameter (value)
          $getOpt_optName = ":";                              # name set to : to indicate error
          $getOpt_prm_flag = "Y";
        }
        else { # we have a winner
          $getOpt_optValue = $PARGV[$getOpt_prm+1];           # set the returned parameter
          $getOpt_prm_flag = "Y";
          $getOpt_prm++;
        }
      }
      else { # parm was required and there are no more parms!
        $getOpt_optValue = $getOpt_prmName;                  # Pass back the option name as the parameter
        $getOpt_optName = ":";                                # name set to : to indicate error
        $getOpt_prm_flag = "Y";
      }
    }
  }
  else { # Parameter is not required
    $getOpt_optValue = "";
    $getOpt_optName = $getOpt_prmName;
    $getOpt_prm_flag = "Y";
  }
  
  return;

} # end of setParameterIfNecessary

# -----------------------------------------------------------------
# getOpt - function to manage the processing of passed parameters
#
# Parameters are of the form 'ab[c]b[c]..[|[d][e]f[c]|[d][e]f[c]....]
#     where a - character to indicate parms are required (normally :)
#           b - option (single character)
#           c - (optional) indicator for parameters (will be the same as parm a). 
#               If there it indicates that option has parameters
#           d - (optional) indicator for multi character option: '--'
#           e - (optional) if ^ indicates that the option is case insensitive
#           f - (optional) long option name
#
#  so an example could be: ':h?d:|--database:|^db: and that would allow parameters like:
#                 test.pl -d testdb
#                 test.pl --database testdb
#                 test.pl dB testdb
#
# NOTE: All single character parameters are case sensitive
#       On the command line:
#           All parameters defined in the single character section must be preceded by '-'
#           All parameters defined in the multi character section must be preceded by either '--' or nothing
#
# Returns: $getOpt_optName : Parameter name if all ok
#                            : if parameter name was ok but required parameter not supplied
#                            * if parameter name was not defined
#          $getopt_optValue: Parameter value if parameter required a parameter
#                            Blank if no parameter required
#                            Parameter name/value if $getOpt_optName set to : or *
# -----------------------------------------------------------------

sub getOpt {

  my $currentRoutine = 'getOpt';
  my $case_insens = "";
  my $getOpt_parmInd = ":";
  my $webParmSet = "";   # initially set no web parm
  my $extendedParameter = 0; # initially parameter is assumed not to be extended

#  our $getOpt_web;
  if ( ! defined($getOpt_calledBy) ) { 
    $getOpt_calledBy = "unknown module";
  }

  if ( (! defined($getOpt_web)) || ($getOpt_web eq '') ) { 
    $getOpt_web = "N";
  }
  
  if ( $getOpt_prm eq "" ) { 
     $getOpt_prm = 0;
  }

  my $QUERY_STRING = $ENV{'QUERY_STRING'};

  if ( ($#_ < 0) && ($QUERY_STRING eq '') ) {
    print STDERR "[$getOpt_calledBy] No parameters passed\n";
    return 0;
  }
 
  $QUERY_STRING =~ s/%27/\'/g; 
  # Define the variables .....

  my $i;
  my $j;
  my $ch;
  my @getOpt_OptArr;
  my $getOpt_tmpKW;
  my $getOpt_KWLen;
  my $getOpt_prmChar;
  my $getOpt_prmName;
  my @webparm;   # used to split parameters by '=' for web use
  my $getOpt_schar;

  # Preparse the input parameters to process concatenated parms 

  if ( ($#PARGV == -1) ) { # Arguments havent been pre-processed yet
    # This is executed only for the first call
    if ( $#ARGV > -1 ) { # only do this bit if parameters are passed
      for ($i=0 ; $i <= $#ARGV ; $i++ ) {        # loop through the arguments
        if ( trim($ARGV[$i]) eq '' ) { next; }   # if the parameter is null then ignore it
        if ( substr($ARGV[$i],0,2) eq "--" ) {   # if it is an extended parameter (begins with --)
          $PARGV[$#PARGV + 1] = $ARGV[$i];
        }
        elsif ( substr($ARGV[$i],0,1) eq "-" ) { # if it starts with a "-"
          # then split up the parameters into separate parms .....
          # (but only if it is non-web and there is no = sign)
          if ( ( $getOpt_web eq "Y" ) && ( index($ARGV[$i],'=') > -1 ) ) {
            # do nothing to the parameter
            my @tmp = split ('=', $ARGV[$i]);
            $PARGV[$#PARGV + 1] = $tmp[0];
            $PARGV[$#PARGV + 1] = $tmp[1];
          }
          else { # space them out .....
            for ( $j=1 ; $j < length($ARGV[$i]) ; $j++ ) {
              $ch = substr($ARGV[$i],$j,1);
              $PARGV[$#PARGV + 1] = "-" . $ch;
            }
          }
        }
        else { # just a parameter
          $PARGV[$#PARGV + 1] = $ARGV[$i];
          if ( substr($PARGV[$#PARGV],0,2) eq "\\\'" ) { # if the parameter starts with \'
            $PARGV[$#PARGV] =~ s/^\\\'//g;  # get rid of the leading characters
            while ( ( $i <= $#ARGV ) && ( substr($ARGV[$i],-2,2) ne "\\\'" ) ) { # parameter is not terminated with a \'
              $i++;
              $PARGV[$#PARGV] .= " " . $ARGV[$i];
            }
            $PARGV[$#PARGV] =~ s/\\\'$//g;  # get rid of the trailing characters
          }
        }
      }
    }

    # now check to see if there are any web GET parameters ....... (but only if there were NO inline parameters)

    displayDebug("[$getOpt_calledBy] \$getOpt_web: $getOpt_web, \$QUERY_STRING: $QUERY_STRING, \$\#PARGV: $#PARGV", 1, $currentRoutine);

    if ( ($QUERY_STRING ne '') && ($#PARGV == -1) ) { # there's web GET form input to process 
    
      my @QPARGV = (); # Query parm ARGV cleared
      # get rid of any 'web' spacing characters (i.e. replace + with ' ')
      $QUERY_STRING =~ s/\+/ /g;
      @QPARGV = split (" ", $QUERY_STRING);

      for ($i=0 ; $i <= $#QPARGV ; $i++ ) {        # loop through the arguments
        if ( substr($QPARGV[$i],0,2) eq "--" ) {   # if it is an extended parameter (begins with --)
          $PARGV[$#PARGV + 1] = $QPARGV[$i];
        }
        elsif ( substr($QPARGV[$i],0,1) eq "-" ) { # if it starts with a "-"
          # then split up the parameters into separate parms .....
          if ( index($QPARGV[$i],'=') > -1 ) { # the parm is of the form A=B so split it up
            # do nothing to the parameter
            my @tmp = split ('=', $QPARGV[$i]);
            for (my  $j=1 ; $j < length($tmp[0]) ; $j++ ) {
             $PARGV[$#PARGV + 1] = '-' . substr($tmp[0],$j,1);
            }
            $PARGV[$#PARGV + 1] = $tmp[1];
          }
          else { # space them out .....
            for ( $j=1 ; $j < length($QPARGV[$i]) ; $j++ ) {
              $ch = substr($QPARGV[$i],$j,1);
              $PARGV[$#PARGV + 1] = "-" . $ch;
            }
          }
        }
        else { # just a parameter
          $PARGV[$#PARGV + 1] = $QPARGV[$i];
          if ( substr($PARGV[$#PARGV],0,2) eq "\\\'" ) { # if the parameter starts with \'
            $PARGV[$#PARGV] =~ s/^\\\'//g;  # get rid of the leading characters
            while ( ( $i <= $#QPARGV ) && ( substr($QPARGV[$i],-2,2) ne "\\\'" ) ) { # parameter is not terminated with a \'
              $i++;
              $PARGV[$#PARGV] .= " " . $QPARGV[$i];
            }
            $PARGV[$#PARGV] =~ s/\\\'$//g;  # get rid of the trailing characters
          }
        }
      }
    }

    # Print out the new array if requested to
    for ($i = 0 ; $i <= $#PARGV ; $i++ ) { displayDebug("[$getOpt_calledBy] (adjusted parms) $i: $PARGV[$i]", 1, $currentRoutine); }
  }

  # Process the parameters ......

  # Parameters are of the form 'ab[c]b[c]..[|[d][e][f][c]|[d][e][f][c]....]
  #     where a - character to indicate parms are required (normally :)
  #           b - option (single character)
  #           c - (optional) indicator for parameters (will be the same as parm a). 
  #               If there it indicates that option has parameters
  #           d - (optional) indicator for multi character option: '--'
  #           e - (optional) if ^ indicates that the option is case insensitive
  #           f - (optional) long option name
  #
  #  so an example could be: ':h?d:|--database:|^db: and that would allow parameters like:
  #                 test.pl -d testdb
  #                 test.pl --database testdb
  #                 test.pl dB testdb

  if (! defined($getOpt_valid_parms{'###'}) ) { # Check if the parm definitions have been read in
    $getOpt_valid_parms{'###'} = "Processed Extended Parms";            # flag that we have processed the parms on the first call in
    @getOpt_OptArr = split(/\|/,$_[0]);  # $_[0] is the single character parameters - split by |
    # Gather the 2nd and subsequent parameters
    $getOpt_parmInd = substr($getOpt_OptArr[0],0,1); # establish the parm indicator character
    for ($i=1 ; $i <= $#getOpt_OptArr ; $i++ ) { # Process the  multi character options (skip the first parameter for later processing)
      if ( substr($getOpt_OptArr[$i],0, 2) eq "--" ) {   # it is an extended parameter
        if ( substr($getOpt_OptArr[$i],2, 1) eq "^" ) {  # it is flagged case insensitive (first char is ^)
          $getOpt_tmpKW = uc(substr($getOpt_OptArr[$i],3));
          $case_insens = 1;
        }
        else { # it is not case insensitive
          $getOpt_tmpKW = substr($getOpt_OptArr[$i],2);
          $case_insens = 0;
        }
        $getOpt_KWLen = length($getOpt_tmpKW);
        if ( substr($getOpt_tmpKW,$getOpt_KWLen-1,1) eq $getOpt_parmInd ) { # it requires a parameter (last char is the parameter indicator)
          $getOpt_tmpKW = substr($getOpt_tmpKW,0,$getOpt_KWLen-1);          # get rid of the indicator
          $getOpt_valid_parms{$getOpt_tmpKW} = ":";                         # non blank indicates it requires a parameter
        }
        else { # it doesn't require a parameter
          $getOpt_valid_parms{$getOpt_tmpKW} = "";                          # flag it as case sensitive
        }
        $getOpt_caseinsens{$getOpt_tmpKW} = $case_insens;
        # only bother to set the flag if it hasn't already been set
        if (! defined($getOpt_requiresDash{$getOpt_tmpKW}) ) {  $getOpt_requiresDash{$getOpt_tmpKW} = 1; } # 
      }
      else { # process it as a keyword 
        $getOpt_tmpKW = $getOpt_OptArr[$i];
        # set up values for supplied parameter (or not)
        if ( substr($getOpt_OptArr[$i],-1,1) eq $getOpt_parmInd ) { # indicator set for provided parameter so alter the parameter name
          $getOpt_KWLen = length($getOpt_tmpKW);
          $getOpt_tmpKW = substr($getOpt_tmpKW,0,$getOpt_KWLen-1);          # get rid of the indicator
          $getOpt_valid_parms{$getOpt_tmpKW} = ':';
        }
        else {
          $getOpt_valid_parms{$getOpt_tmpKW} = ' ';
        }
        
        if ( substr($getOpt_OptArr[$i],0, 1) eq "^" ) {     # it is case insensitive 
          $getOpt_tmpKW = uc(substr($getOpt_OptArr[$i],1)); # parameter starts after 1st char
          $getOpt_caseinsens{$getOpt_tmpKW} = 1;          # flag it as case insensitive
        }
        else {
          $getOpt_caseinsens{$getOpt_tmpKW} = 0;
        }
      }
      $getOpt_requiresDash{$getOpt_tmpKW} = 0;
      $search_valid_parms .= " $getOpt_tmpKW ";
    }
  }
  
  # Process the 1st parameter separately ....
  $getOpt_schar = 0;
  if (! defined($getOpt_valid_parms{'####'}) ) { # Has this parm already been processed?
    $getOpt_valid_parms{'####'} = "Processed First Parm";            # flag that we have processed the parms on the first call in
    $getOpt_schar++;          # skip the first character as it is the parameter indicator
    # now process each of the character options .....
    while ( $getOpt_schar <= length($getOpt_OptArr[0])-1 ) {
      $getOpt_prmChar = substr($getOpt_OptArr[0],$getOpt_schar,1);   # set option
      $getOpt_valid_parms{$getOpt_prmChar} = "";                     # set it up as a valid option without parm
      $getOpt_caseinsens{$getOpt_prmChar} = 0;                       # set it up as case sensitive (note all single char options are case sensitive)
      # only bother to set the requiresDash flag if it hasn't already been set
      if (! defined($getOpt_requiresDash{$getOpt_prmChar}) ) {  $getOpt_requiresDash{$getOpt_prmChar} = 1; } # 
      $getOpt_schar++;
      if ( $getOpt_schar <= length($getOpt_OptArr[0])-1 ) { # if still more chars check if it is a flag       
        if ( substr($getOpt_OptArr[0],$getOpt_schar,1) eq $getOpt_parmInd ) { # Flagged as requiring parameters
          $getOpt_valid_parms{$getOpt_prmChar} = ":";                # set option as requiring parm
          $getOpt_schar++;
        }
      }
    }
  }
  $getOpt_prm_flag = "N";

  displayDebug(  "[$getOpt_calledBy] ================================================<BR>", 1, $currentRoutine);
  displayDebug(  "[$getOpt_calledBy] \$\#ARGV=$#ARGV<BR>", 1, $currentRoutine);
  for ($i=0 ; $i <= $#ARGV ; $i++ ) {
    displayDebug(  "[$getOpt_calledBy] ARGS $i>$ARGV[$i]<BR>", 1, $currentRoutine);
  }
  displayDebug(  "[$getOpt_calledBy] Query parms string: $QUERY_STRING<BR>", 1, $currentRoutine);
  displayDebug(  "[$getOpt_calledBy] \$\#PARGV=$#PARGV<BR>", 1, $currentRoutine);
  for ($i=0 ; $i <= $#PARGV ; $i++ ) {
    displayDebug(  "[$getOpt_calledBy] PARGS $i>$PARGV[$i]<BR>", 1, $currentRoutine);
  }
  displayDebug(  "[$getOpt_calledBy] \$\#=$#_<BR>", 1, $currentRoutine);
  for ($i=0 ; $i <= $#_ ; $i++ ) {
    displayDebug(  "[$getOpt_calledBy] PRM $i>$_[$i]<BR>", 1, $currentRoutine);
  }
  if (defined($PARGV[$getOpt_prm]) ) {
    displayDebug(  "[$getOpt_calledBy] Current Parm:$PARGV[$getOpt_prm]<BR>", 1, $currentRoutine);
  }
  displayDebug(  "[$getOpt_calledBy] \$getOpt_valid_parms ....<BR>", 1, $currentRoutine);
  #foreach $key (sort by_key keys %getOpt_valid_parms ) {
  #  displayDebug( "$key = $getOpt_valid_parms{$key}<BR>", 1, $currentRoutine);
  #}
  displayDebug(  "[$getOpt_calledBy] ================================================<BR>", 1, $currentRoutine);

  # Now start processing the actual parameters
  
  my $parmDashInd = 0;                                              # indicates that the parameter is preceded by a dash (preceeded by - or --)
  my $parmDashes = '';

  while ($getOpt_prm_flag ne "Y") {                                 # We are still looking
    $parmDashInd = 0;
    if ( defined($PARGV[$getOpt_prm]) ) {                           # if a passed argument exists
      $getOpt_prmName = trim($PARGV[$getOpt_prm]);                  # strip whitespace from the parameter
      if ( substr($PARGV[$getOpt_prm],0,1) eq "-") {                # if it is a parameter (ie starts with a dash) then strip the leading -
        $parmDashes = '-';                                          # remember it is 1 dash
        $parmDashInd = 1;
        $getOpt_prmName = trim(substr("$getOpt_prmName  ",1));      # remove the first character
        if ( substr($getOpt_prmName,0,1) eq "-" ) {                 # if it is an extended parameter ....
          $getOpt_prmName = trim(substr("$getOpt_prmName  ",1));    # remove the first char again
          $extendedParameter = 1;                                   # flag that the parameter is extended
          $parmDashes = '--';                                        # remember it is 2 dashes
        }
      }

      # and now it gets interesting ......
      # If we are in HTML-land (ie $getOpt_web is "Y" ) then we can also also have parameters of
      # the form -p=A -d=database so a single entry may actually contain the option and
      # the parameter

      if ( $getOpt_web eq "Y" ) {                      # must cope with web parameter format as well
        if ( index($getOpt_prmName,'=') > -1 ) {      # the parm contains an = sign
          @webparm  = split('=',$getOpt_prmName);     # split it on the = sign
          displayDebug( "web initial: $getOpt_prmName<BR>", 1, $currentRoutine);
          displayDebug( "web option: $webparm[0] parm: $webparm[1]<BR>", 1, $currentRoutine);
          $getOpt_prmName = $webparm[0];              # establish a new parameter value
          $webParmSet = $webparm[1];                   # set the parameter value
        }
      }
      
      # construct the name to check against
      my $testParmName = $getOpt_prmName;
      if ( $getOpt_caseinsens{uc($getOpt_prmName)} ) { $testParmName = uc($getOpt_prmName); }

      if ( ( defined($getOpt_valid_parms{$testParmName} ) ) )  {  # is it a valid parameter? defined = yes
        if ( $getOpt_requiresDash{$testParmName} ) {              # check to see if the parm required a dash (and if it had one)
          if ( $parmDashInd ) {                                   # dash required and found so it is a paramter name
            $getOpt_prmName = $testParmName;                       # if it is case insensitive then make the option upper case
            setParameterIfNecessary($getOpt_prmName, $webParmSet, "");
          }
          else {                                                  # no dash so not a parameter name 
            $getOpt_optName = '*';                                # flag the fact that name isn't known
            $getOpt_optValue = $parmDashes . $testParmName;
            $getOpt_prm_flag = "Y";
          }
        }
        else {
          if ( $getOpt_caseinsens{uc($getOpt_prmName)} ) {
            $getOpt_prmName = uc($getOpt_prmName);                # if it is case insensitive then make the option upper case
          }
          setParameterIfNecessary($getOpt_prmName, $webParmSet, "");
        }
      }
      else { # it is not a valid parameter (or at least it wasn't defined)
        if ( $extendedParameter || ( length($getOpt_prmName) > 1) ) { # if it is an extended parameter (starts with -- or > 1 character in length) then a partial match may be valid
          if ( $getOpt_min_match == -1 ) { # match must be for whole parameter so it has failed
            $getOpt_optName = "*";
            $getOpt_optValue = $parmDashes . $getOpt_prmName;
            $getOpt_prm_flag = "Y";
          }
          else { # try progressive testing if the string is above or equal to the min match limit
            if ( length($getOpt_prmName) >= $getOpt_min_match ) { # big enough to try and match
              # first try case sensitive
              my $tmpIndex = index($search_valid_parms," " . $getOpt_prmName); # check to see if we can find the restricted parm name in the table
              my $tmpIndex2 = -1;     # this will hold the char position ofthe end ofthe parameter name
              my $tmpParmName = '';   # will hold the trial parameter name
              if ( $tmpIndex > -1 ) { # the string was found (so set up variables and exit loop)
                $tmpIndex2 = index($search_valid_parms," ", $tmpIndex+1); # search for the next space past the found string
                my $tmpParmName = substr($search_valid_parms, $tmpIndex+1, $tmpIndex2 - $tmpIndex - 1);
                $getOpt_prm_flag = "Y";
                $getOpt_optName = $tmpParmName;
                # Decide if a parameter is needed and get it if possible
                setParameterIfNecessary($tmpParmName, "", $getOpt_prmName);
              }
              else { # string not found so try case insensitive
                $tmpIndex = index($search_valid_parms," " . uc($getOpt_prmName)); # check to see if we can find the restricted parm name in the table
                if ( $tmpIndex > -1 ) { # the string was found , check if it is a case insensitve parameter
                  $tmpIndex2 = index($search_valid_parms," ", $tmpIndex+1); # search for the next space past the found string
                  my $tmpParmName = substr($search_valid_parms, $tmpIndex+1, $tmpIndex2 - $tmpIndex - 1);
                  if ( $getOpt_caseinsens{$tmpParmName} ) { # the parameter is case insensitive so it is a match
                    $tmpIndex2 = index($search_valid_parms," ", $tmpIndex+1); # search for the next space past the found string
                    $getOpt_prm_flag = "Y";
                    $getOpt_optName = $tmpParmName;
                    # Decide if a parameter is needed and get it if possible
                    setParameterIfNecessary($tmpParmName, "", $getOpt_prmName);
                  }
                  else { # it is not case sesitive so this isn't a match 
                    $getOpt_optName = "*";
                    $getOpt_optValue = $parmDashes . $getOpt_prmName;
                    $getOpt_prm_flag = "Y";
                  }
                }
                else { # string wasn't found 
                  $getOpt_optName = "*";
                  $getOpt_optValue = $parmDashes . $getOpt_prmName;
                  $getOpt_prm_flag = "Y";
                }
              }
            }
            else { # extended parameter but shorter then the minimum match length so fail
              $getOpt_optName = "*";
              $getOpt_optValue = $parmDashes . $getOpt_prmName;
              $getOpt_prm_flag = "Y";
            }
          }
        }
        else { # not extended parameter and not above minimum match limit
          $getOpt_optName = "*";
          $getOpt_optValue = $parmDashes . $getOpt_prmName;
          $getOpt_prm_flag = "Y";
        }
      }
      $getOpt_prm++;
    }
    else {
      $getOpt_optName = "";
      $getOpt_optValue = "";
      $getOpt_prm_flag = "Y";
      return 0;
    }
  }
  
  if ( $getOpt_web eq 'Y' ) { 
    $getOpt_optValue =~ s/\\\\/##DBS##/g  ;  # change all double backslashes to a special code
    $getOpt_optValue =~ s/\\//g  ;           # remove all surviving backslashes
    $getOpt_optValue =~ s/##DBS##/\\/g  ;    # convert special backslash code to single backslash
    $getOpt_optValue =~ s/\\'/'/g  ;    # convert special backslash code to single backslash
  }
  
  return $getOpt_optName;
} # end of getOpt

# -----------------------------------------------------------------
# getOpt_form - function to manage the processing of passed parameters
#               similar to getOpt but no definitions. All parameters are 
#               either passed back as themselves or if there is an equals
#               sign then they are passed baclk with the element to the
#               right of the equals sign
# -----------------------------------------------------------------

sub getOpt_form {

  my $webParmSet = "";        # initially set no web parm
  my @tmpParms = ();          

  if ( ! defined($getOpt_calledBy) ) { 
    $getOpt_calledBy = "unknown module";
  }

  my $QUERY_STRING;

  if ( ! @QPARGV ) { # first pass
    # establish web input
    if ( $getOpt_web eq "Y" ) {                 # web input so check the web parameter string as well ....
      $QUERY_STRING = $ENV{'QUERY_STRING'};     # if the HTML method was GET then just preload this data 
      if ( $ENV{'REQUEST_METHOD'} eq "POST" ) { # make allowances for POST method of supplying parameters
        read(STDIN,$QUERY_STRING, $ENV{'CONTENT_LENGTH'});
      }
    }

    # check if any parms were passed on the first call
    if ( ($#_ < 0) && ($QUERY_STRING eq '')  && (! @QPARGV ) ) {
      print STDERR "[$getOpt_calledBy] No parameters passed on first pass\n";
      return 0;
    }
    else { # there were parameters supplied
      if ( $#_ >= 0 ) {                   # parameters passed on the command line
          push @QPARGV, @ARGV;            # save the ARGV parameters away
      }

      # process the web parameters if any were supplied
      if ( $QUERY_STRING ne '' ) {      # there are web parameters
        @tmpParms = split (/[$parmSeparators]+/, $QUERY_STRING);
        push @QPARGV, @tmpParms;        # add the web parms to the held parm array
      }
    }
  }

  # Define the variables .....

  my $i;
  my $j;
  
  $getOpt_optName = '';                       # initialis the ename

  # process the parameter held in array entry $getOpt_prm (which holds which parm we are currently processing)
  
  if ( $#QPARGV > -1 ) { # there are parms
    if ( $getOpt_prm <= $#QPARGV ) { # we're processing an element that exists

      if ( $QPARGV[$getOpt_prm] =~ /=/ ) {                # if the parameter has an equals sign then find the vaslue
        ($getOpt_optName, $getOpt_optValue) = split ('=', $QPARGV[$getOpt_prm]); 
      }
      else {
        $getOpt_optName = $QPARGV[$getOpt_prm];
        $getOpt_optValue = $QPARGV[$getOpt_prm];
      }
    }
    $getOpt_prm++;                                       # prepare to process the next item
  }

  # replace web inserted characters
  $getOpt_optValue =~ s/\+/ /g;
  
  if ( $getOpt_optName eq '' ) { # no entry was found
    return 0;
  }
  else { # something has been found to process
    return 1;
  }

} # end of getopt_form

# -----------------------------------------------------------------
# trim - function to strip whitespace from the start and end of a 
#        string
# -----------------------------------------------------------------

sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
} # end of trim

# -----------------------------------------------------------------
# ltrim - function to strip whitespace from the start of a string 
# -----------------------------------------------------------------

sub ltrim {
  my $string = shift;
  $string =~ s/^\s+//;
  return $string;
} # end of ltrim

# -----------------------------------------------------------------
# rtrim - function to strip whitespace from the end of a string 
# -----------------------------------------------------------------

sub rtrim {
  my $string = shift;
  $string =~ s/\s+$//;
  return $string;
} # end of rtrim

# -----------------------------------------------------------------
# leapYear - test if a date is a leap year 
# -----------------------------------------------------------------

sub leapYear {
  my $yr = shift;

  my $Rem = $yr % 4;
  if ( $Rem == 0 ) {
    if ( ($yr % 400) == 0) {
      return 0;
    }
    else {
      return 1;
    }
  }  
  else {
    return 0;
  }
} # end of leapYear

sub convertDurationToTimestamp {
  # -----------------------------------------------------------
  # This routine will convert a number of units to a standard timestamp
  #
  # Units can be specified as:
  #    Y - years
  #    m - months
  #    D - Days
  #    H - Hours
  #    M - Minutes
  #    S - Seconds
  #
  # NOTE: when dealing with S, M ,H or D the number of days returned may
  #       be greater than the number of days in a month
  #       i.e. a call of convertDurationToTimestamp("51196") would return
  #            "0000-00-35 13.16.00"
  #
  # Usage: $timestamp = convertDurationToTimestamp('duration', 'units');
  # Returns: a timestamp representing the specified duration 
  # -----------------------------------------------------------
  
  my $currentSubroutine = 'convertDurationToTimestamp';

  my $duration = shift;
  my $UOM = shift;
  if ( ! defined($UOM) ) { $UOM = 'M' } # default UOM is minutes
  
  my $year = '0000';
  my $month = '00';
  my $day = '00';

  my $hour = '00';
  my $min = '00';
  my $sec = '00';

  if ( $UOM eq 'S' ) { # duration is in minutes ...
    $sec = $duration % 60;              # seconds   
    $duration= ($duration - $sec) / 60;  #duration is now # minutes
    $min = $duration % 60;               # minutes   
    $duration= ($duration - $min) / 60;  #duration is now # hours
    $hour = $duration % 24;              # hours 
    $day = ($duration - $hour) / 24;     # duration is now # days
  }
  elsif ( $UOM eq 'M' ) { # duration is in minutes ...
    $min = $duration % 60;               # minutes   
    $duration= ($duration - $min) / 60;  #duration is now # hours
    $hour = $duration % 24;              # hours 
    $day = ($duration - $hour) / 24;     # duration is now # days
  }
  elsif ( $UOM eq 'H' ) { # duration is in minutes ...
    $hour = $duration % 24;              # hours 
    $day = ($duration - $hour) / 24;     # days
  }
  elsif ( $UOM eq 'm' ) { # duration is in months ...
    $month = $duration % 12;             # months 
    $year = ($duration - $month) / 12;   # years
  }
  elsif ( $UOM eq 'Y' ) { # duration is in years ...
    $year = $duration;                   # years
  }
  elsif ( $UOM eq 'D' ) { # duration is in days ...
    $day = $duration;                    # days    
  }

  my $ts = sprintf "%04d-%02d-%d %02d.%02d.%02d",$year,$month,$day,$hour,$min,$sec;
  return $ts;

} # end of convertDurationToTimestamp

sub isNumeric {
  # -----------------------------------------------------------
  # Routine to check if a supplied parameter is a number or not
  #
  # Usage: isnumeric('123');
  # Returns: 0 - not numeric , 1 numeric
  # -----------------------------------------------------------

  my $currentSubroutine = 'isNumeric';

  my $var = shift;

  if ($var =~ /^\d+\z/)         { return 1; } # only contains digits between the start and the end of the bufer
  displayDebug("Not Only Digits",5,$currentSubroutine);
  if ($var =~ /^-?\d+\z/)       { return 1; } # may contain a leading minus sign
  displayDebug("Doesn't have a leading minus followed by digits",5,$currentSubroutine);
  if ($var =~ /^[+-]?\d+\z/)    { return 1; } # may have a leading minus or plus
  displayDebug("No leading minus or plus followed by digits",5,$currentSubroutine);
  if ($var =~ /^-?\d+\.?\d*\z/) { return 1; } # may have a leading minus , digits , decimal point and then digits
  displayDebug("Not a negative decimal number",5,$currentSubroutine);
  if ($var =~ /^[+-]?(?:\d*\.\d)?\d*(?:[Ee][+-]?\d+)\z/) { return 1; }
  displayDebug("Not scientific notation",5,$currentSubroutine);

  return 0;

} # end of isNumeric

sub processDuration {
  # -----------------------------------------------------------
  # processDuration will take a string which may be a duration and
  # if it is a duration will return the duration in the units
  # requested (the unit requested becomes the default unit)
  #
  # A duration can be of the form:
  #    1. 1 day 4 hours 3 mins 8 seconds
  #    2. 4
  #    3. 1 day 3 mins
  #
  # Units can be specified as:
  #    D - Days
  #    H - Hours
  #    M - Minutes
  #    S - Seconds
  #    T - Timestamp (in this case the default unit will be minutes)
  #
  # Note that durations for non timestamps will be calculated from the current date 
  # to try and accomodate leap years and varying numbers of days in months
  #
  # Usage: ($isDuration, $duration) = processDuration('string', 'units');
  # Returns: a flag indiacting if it was a duration and the duration in the units specified
  # -----------------------------------------------------------

  my $currentRoutine = 'processDuration';
  
  my $duration = shift;    # duration to be evaluated
  my $UOM = shift;         # unit of measure (one of D,H,M,S or T)
  if ( ! defined($UOM) ) { $UOM = 'M' } # unit of measure defaults to M
  
  my $year = '';
  my $month = '';
  my $day = '';
  
  my $hour = '';
  my $min = '';
  my $sec = '';
  
  my @durationParts = split(" ", $duration); # break the duration up 
  
  if ( $#durationParts == 0 ) { # only one element to the duration
    if ( isNumeric($durationParts[0]) ) { # it's a number so all good
      if ( $UOM = 'T' ) { # if only 1 parameter then it default to number of minutes
        return (1,convertDurationToTimestamp($duration));
      }
      else {
        return (1, $duration); 
      }
    }
    else { # not a number so cant be a duration
      return (0,$duration);
    }
  }
  else { # check to see if it is a real duration
    if ( $#durationParts % 2 == 1 ) { # there are an even number of parameters (array starts from 0)
      for ( my $i=0 ; $i < $#durationParts ; $i=$i+2 ) { # process each pair of parameters
        my $lenUnit = length($durationParts[$i+1]);
        if ( substr("YEARS",0,$lenUnit) eq uc($durationParts[$i+1]) ) { # unit Years
          if ( isNumeric($durationParts[$i]) ) { # it is a valid number
            $year = int($durationParts[$i]);
          }
          else { # invalid value
            return (0,$duration);
          }
        }
        elsif ( substr("MONTHS",0,$lenUnit) eq uc($durationParts[$i+1]) ) { # unit Months
          if ( isNumeric($durationParts[$i]) ) { # it is a valid number
            $month = int($durationParts[$i]);
          }
          else { # invalid value
            return (0,$duration);
          }
        }
        elsif ( substr("DAYS",0,$lenUnit) eq uc($durationParts[$i+1]) ) { # unit Days
          if ( isNumeric($durationParts[$i]) ) { # it is a valid number
            $day = int($durationParts[$i]);
          }
          else { # invalid value
            return (0,$duration);
          }
        }
        elsif ( substr("HOURS",0,$lenUnit) eq uc($durationParts[$i+1]) ) { # unit Hours
          if ( isNumeric($durationParts[$i]) ) { # it is a valid number
            $hour = int($durationParts[$i]);
          }
          else { # invalid value
            return (0,$duration);
          }
        }
        elsif ( substr("MINUTES",0,$lenUnit) eq uc($durationParts[$i+1]) ) { # unit Minutes
          if ( isNumeric($durationParts[$i]) ) { # it is a valid number
            $min = int($durationParts[$i]);
          }
          else { # invalid value
            return (0,$duration);
          }
        }
        elsif ( substr("SECONDS",0,$lenUnit) eq uc($durationParts[$i+1]) ) { # unit Seconds
          if ( isNumeric($durationParts[$i]) ) { # it is a valid number
            $sec = int($durationParts[$i]);
          }
          else { # invalid value
            return (0,$duration);
          }
        }
        else { # unit of measure is not known 
          return(0,$duration);
        }
      }
      # all values have now been set - adjust as necessary
      my $tmp = 0;
      if ( $sec > 59 ) {
        $tmp = $sec % 60; 
        $min = $min + ( ($sec - $tmp) / 60);
        $sec = $tmp;
      }      
      if ( $min > 59 ) {
        $tmp = $min % 60; 
        $hour = $hour + ( ($min - $tmp) / 60);
        $min = $tmp;
      }      
      if ( $hour > 23 ) {
        $tmp = $hour % 24; 
        $day = $day + ( ($hour - $tmp) / 24);
        $min = $tmp;
      }      
      if ( $month > 11 ) {
        $tmp = $month % 12; 
        $year = $year + ( ($month - $tmp) / 24);
        $month = $tmp;
      }
      displayDebug("Parts - UOM=$UOM, year=$year, month=$month, day=$day, hour=$hour, minute=$min, seconds=$sec",1,$currentRoutine);
      # all adjusted now  
      if ( $UOM eq 'T' ) { # Returned parameter MUST be a timestamp
        my $ts = sprintf "%04d-%02d-%d %02d.%02d.%02d",$year,$month,$day,$hour,$min,$sec;
        displayDebug("Returning $ts after formatting",1,$currentRoutine);
        return (1,$ts);
      }  
      elsif ( $UOM eq 'S' ) { # returned value is number of seconds 
        my $tmp_secs = ((($hour * 60 ) + $min) * 60) + $sec;    # number of seconds in the hr/min/sec part
        # to work out the date part in seconds we need to work out 
        
        if ( ($year + $month + $day ) > 0 ) { # date information was input
          displayDebug("durationDays returned " . durationDays($day, $month, $year) . " and tmp_secs=$tmp_secs",1,$currentRoutine);
          return (1, (durationDays($day, $month, $year) * 24 * 60 * 60) + $tmp_secs);
        }
        else { # just time parts
          return (1, $tmp_secs);
        }
      }
      elsif ( $UOM eq 'M' ) { # returned value is number of minutes
        my $tmp_mins = ($hour * 60 ) + $min ;   # number of minutes in the hr/min/sec part
        
        # to work out the date part in minutes we need to work out 
        if ( ($year + $month + $day ) > 0 ) { # date information was input
          displayDebug("durationDays returned " . durationDays($day, $month, $year) . " and tmp_mins=$tmp_mins",1,$currentRoutine);
          return (1, (durationDays($day, $month, $year) * 24 * 60 ) + $tmp_mins);
        }
        else { # just time parts
          return (1, $tmp_mins);
        }
      }
      elsif ( $UOM eq 'H' ) { # returned value is number of hours
        my $tmp_hrs = $hour  ;             # number of hours in the hr/min/sec part
        
        # to work out the date part in hours we need to work out 
        if ( ($year + $month + $day ) > 0 ) { # date information was input
          displayDebug("durationDays returned " . durationDays($day, $month, $year) . " and tmp_hrs=$tmp_hrs",1,$currentRoutine);
          return (1, (durationDays($day, $month, $year) * 24) + $tmp_hrs);
        }
        else { # just time parts
          return (1, $tmp_hrs);
        }
      }
      elsif ( $UOM eq 'D' ) { # returned value is number of days
        
        # to work out the date part in hours we need to work out 
        if ( ($year + $month + $day ) > 0 ) { # date information was input
          displayDebug("durationDays returned " . durationDays($day, $month, $year),1,$currentRoutine);
          return (1, durationDays($day, $month, $year));
        }
        else { # the date part was zero
          return (1, "0");
        }
      }
    }
    else { # odd number of parameters not allowed - each value must have a unit 
      return (0,$duration);
    }
  }
  
} # end of processDuration

sub durationDays {
  # -----------------------------------------------------------
  # Routine to return the number of days from today till the
  # date indicated by the days, months and years parameters
  #
  # Usage: durationDays($day, $month, $year);
  # Returns: the number of days between now and the duration specified
  # -----------------------------------------------------------

  my $currentRoutine = 'durationDays';
  
  my $day = shift;
  my $month = shift;
  my $year = shift;

  my $heldDay = $day;

  displayDebug( "year=$year, month=$month, day=$day", 1, $currentRoutine);
  my $tmp2 = getDate(2);
  my @T = myDate("DATE\:$tmp2");   # number of days from base date to today
  my $baseToToday = $T[5];
  displayDebug( "number of days to today : $baseToToday", 1, $currentRoutine);
  $day = $day + $T[5];             # $day now points to the date after addition of days
  @T = myDate($day);               # now have the date after days addition 
  displayDebug( "Date $heldDay days in the future: $T[0]/$T[1]/$T[2]", 1, $currentRoutine);
  $day = $T[0];
  $month = $month + $T[1];         # add any extra months
  if ( $month > 12 ) {             # adjust months as necessary
    $month = $month - 12;
    $year++;
  }
  $year = $year + $T[2] ;          # add any years if necessary        
  displayDebug( "Date after adding in year and month : $day/$month/$year", 1, $currentRoutine);
  $year = sprintf("%04d",$year);
  $month = sprintf("%02d",$month);
  $day = sprintf("%02d",$day);
  @T = myDate("DATE\:$year$month$day"); # $T[5] now contains the number of days after
                                        # after adding on months and years to today
  displayDebug( "Number of days to that date: $T[5], returning this less $baseToToday", 1, $currentRoutine);
  return $T[5]-$baseToToday;               # return the difference in the number of days
  
} # end of durationDays

sub isValidTimestamp {
  # -----------------------------------------------------------
  # Routine to check if a string is a timestamp
  #
  # A timestamp MUST be of the format "YYYY*MM*DD*HH*mm*SS"
  #
  # Usage: if ( isTimestamp($timestring) ) { # do something }
  # Returns: 1 if the string is a timestamp
  # -----------------------------------------------------------

  my $currentSubroutine = 'isValidTimestamp';

  my $checkString = shift;
  
  # string MUST be 19 chars long 
  if ( length ( $checkString ) != 19 ) { return 0; } 
  # break out the digits
  my ($year,$month,$day,$hour,$min,$sec) = ($checkString =~ /(\d\d\d\d).(\d\d).(\d\d).(\d\d).(\d\d).(\d\d)/ ) ;
  
  # check that the split out worked (ie numbers where numbers should be)
  if ( ! defined($year) ) { return 0; }  
  
  if ( isValidDate("$year-$month-$day") ) { # do checks on the time ....
    if ( $hour > 23 ) { return 0; } # Hour must be 00 -> 23
    if ( $min > 59 ) { return 0; }  # Minutes must be 00 -> 59
    if ( $sec > 59 ) { return 0; }  # Seconds must be 00 -> 59
  }
  else {
    return 0; # date is not valid
  }
  
  # to get here everything must look ok
  
  return 1;

} # end of isValidTimestamp

sub isValidDate {

  # -----------------------------------------------------------
  # Routine to check if a string is a date
  #
  # A date MUST be of the format "YYYY*MM*DD"
  #
  # Usage: if ( isValidDate($date) ) { # do something }
  # Returns: 1 if the string is a date
  # -----------------------------------------------------------

  my $currentSubroutine = 'isValidDate';

  my $checkDate = shift;
  
  if ( ! defined($checkDate) ) { return 0; }    # must have something to check
  if ( length($checkDate) != 10) { return 0; }  # must be 10 chars long

  my ( $year,$month,$day ) = ( $checkDate =~ /(\d\d\d\d).(\d\d).(\d\d)/ );
  
  if ( ! defined($year) ) { return 0; }         # doesn't match the mask for digits

  if ( ($month eq '00')    || ( $month > 12) ) { return 0; } # invalid month number
  
  if ( $month == 2 ) { # february
    if ( leapYear($year) ) { # it is a leap year
      if ( $day > 29 ) { return 0; }            # has greater than 29 days in leap year february
    }
    else { # not a leap year
      if ( $day > 28 ) { return 0; }            # has greater than 28 days in non leap year february
    }
  }
  elsif ( $day > $monthDays[$month] ) {         # for the rest just check the array
    return 0;                                   # too many days
  }
    
  return 1; # can find no issues
  
} # end of isValidDate

# -----------------------------------------------------------------
# date - function to provide date related functions 
# -----------------------------------------------------------------

sub myDate {

  my $currentRoutine = 'myDate';
  my $Base = "1965";
  my $GenDays = "N";
  my $EOY  = "N"; # End of Year
  my $EOFY = "N"; # End of Financial Year
  my $EOM  = "N"; # End of Month
  my $BOM  = "N"; # Beginning of Month Flag
  my $EDD = '';
  my $EMM = '';
  my $EYY = '';
  my $Suff = '';
  my $Month = '';
  my $NumDays = '';
  my $DOW = '';
  my $BaseDate = '';
  my $RetMSG = "";
  my @pv_pair; # array to hold parameter parm/value pair
  my $Date ; # parameter value date of the form YYYYMMDD
  my $genDays; # parameter value of the number of days since the base date
  my $BaseCentury ; # Century of the Base date
  my $BaseYear ; # Year of the base date
  my $Century ; # Will eventually be the century of the returned date
  my $Year ; # will eventually be the year of the returned date
  my $Rem ; # field use in calculating leap years
  my $LeapYear ; # indicator for a leap year
  my $DaysInYear ; #  
  my $Rem2 ; # field use in calculating leap years
  my $Tyear ; #
  my @cumDays ; # cummulative days
  my $i ; # loop variable
  my $j ; # loop variable
  my $DD ; # Day variable
  my $MM ; # month variable
  my $YY ; # year variable
  my $lastMonth;
  my $Last2Digit; # Used in establishing the date suffix
  my $LastDigit ; # Used in establishing the date suffix
  my $tmp;
  my $AddBit ; # date adjuster for date pre and post the end of February
  my $DOW19650101 = "FRI";
  my @DOWliterals = ("SUN","MON","TUE","WED","THU","FRI","SAT");
  
  displayDebug( "myDate Debug level set to $cF_debugLevel", 1, $currentRoutine);   
  
  if ($#_ == -1) {
    $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy] ";
    return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
  }

  my $prmInput = @_;
  my @parms = split(/ /,"@_");
  my $HoldDays = $parms[0];
  my $dateAdjust = 0;

  $monthDays[2] = 28;

  # so at least 1 parameter to get here ...

  if ( length($parms[0]) > 5 ) {
    if ( $parms[0] =~ /:/ ) { # of the form parm:value
      if ( uc(substr($parms[0],0,4)) eq "DATE" ) {
        @pv_pair = split(/\:/,$parms[0],2);
        $Date = $pv_pair[1];
        $GenDays = "Y";
      }
      else {
        $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }
    elsif ($parms[0] =~ /=/) { # of the form parm=value
      if ( uc(substr($parms[0],0,4)) eq "DATE") {
        @pv_pair = split(/=/,$parms[0],2);
        $Date = $pv_pair[1];
        $GenDays = "Y";
      }
      else {
        $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }
    else { # it is to be treated as a number of days from the base date of 01/01/1965
    }
  }

  if ($#parms > 0) { # At least 2 parameters (only the first two will be used )
    if ( length($parms[1]) > 5 ) {
      if ( $parms[1] =~ /:/ ) { # of the form parm:value
        if ( uc(substr($parms[1],0,4)) eq "BASE" ) {
          @pv_pair = split(/\:/,$parms[1],2);
          $Base = $pv_pair[1];
        }
        else {
          $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
          return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
        }
      }
      elsif ($parms[1] =~ /=/) { # of the form parm=value
        if ( uc(substr($parms[1],0,4)) eq "BASE") {
          @pv_pair = split(/=/,$parms[1],2);
          $Base = $pv_pair[1];
        }
        else {
          $RetMSG = "Usage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
          return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
        }
      }
      else { # it is to be treated as a number of days from the base date supplied
      }
    }
  }

  if ( length($Base) != 4 ) {
    $RetMSG = "Base date MUST be a four digit number\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\nYour Input: $prmInput ";
    return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
  }
  else {
    $BaseDate = $Base;
  }

  $BaseCentury = substr($BaseDate,0,2);
  $BaseYear = substr($BaseDate,2,2);

  if ( $GenDays eq "N" ) {
    $NumDays = $parms[0];
    $Century = $BaseCentury;
    $Year = $BaseYear;
    
    displayDebug( "Processing Julian Date of $NumDays", 1, $currentRoutine); 

    # Calculate how many days between 01/01/1965 and the base date (for calculating the DOW)
    
    if ( $BaseDate ne '1965' ) { # a new base date has been set .....
      foreach my $yr  ('1965' .. $BaseDate) {
        if ( $yr ne $BaseDate ) { # only do it up to but not including the base date
          if ( leapYear($yr) ) { 
            $dateAdjust = $dateAdjust + 366;
          }
          else {
            $dateAdjust = $dateAdjust + 365;
          }
        }
      }
      displayDebug( "Days between 01/01/1965 and 01/01/$BaseDate is $dateAdjust", 1, $currentRoutine); 
    }
    
    # Calculate how many full years have passed since the base date

    while ( $NumDays > 0 ) {
      $Rem = $Year % 4;
      if ( $Rem == 0 ) {
        if ( ($Year % 400) == 0) {
          $LeapYear = "No";
          $DaysInYear = 365;
        }
        else {
          $LeapYear = "Yes";
          $DaysInYear = 366;
        }
      }
      else {
        $LeapYear = "No";
        $DaysInYear = 365;
      }
      $NumDays = $NumDays - $DaysInYear;
      $Year = $Year + 1;
      if ( $Year == 100 ) {
        $Year = 0;
        $Century = $Century + 1;
      }
    }
    
    # Adjust date for the partial year

    $Year = $Year - 1;
    $Year = substr("0" . $Year, length($Year)-1,2);   # make it 2 digits
    displayDebug( "The Year calculated for 01/01/$BaseDate + numDays is $Century$Year", 1, $currentRoutine); 
 
    $NumDays = $NumDays + $DaysInYear;          # NumDays is positive again and should now hold the number of days in the last year
    displayDebug( "Number of days in the last year is $NumDays", 1, $currentRoutine); 

    # Adjust the array if it is a leap year
    $monthDays[2] = 28;
    $Tyear = "$Century$Year";
    $Rem = $Tyear % 4;
    if ( $Rem == 0 ) {
      $Rem2 = $Tyear % 400;
      if ( $Rem2 != 0 ) {
        $monthDays[2] = 29 ;  # it's a leap year so Feb has 29 days
      }
    }
    
    # Establish the cummulative counts .....
    $i = 2;
    $cumDays[0] = 0;
    $cumDays[1] = 0;
    for ($i ; $i < 13 ; $i++ ) {
      $lastMonth = $i - 1;
      $cumDays[$i] = $cumDays[$lastMonth] + $monthDays[$lastMonth];
    }
    
    displayDebug( "Cummulative Month ", 1, $currentRoutine); 
    for ( my $k = 0 ; $k <= 12 ; $k++ ) {
      displayDebug( "$k value is $cumDays[$k] - ", 1, $currentRoutine); 
    }
    
    # work down through the cummulative counts until you get to the point where Numdays is greater than 
    # the cummlative day count for the year

    for ($i = 12; $i > 0 ; $i-- ) {
      if ($NumDays > $cumDays[$i]) {
        $MM = $i;
        $DD = $NumDays - $cumDays[$i];
        last;
      }
    }

    displayDebug( "Calculated month is $MM as the cummulative day count was $cumDays[$i] and the number of days in the year was $NumDays", 1, $currentRoutine); 
    displayDebug( "Calculated day is $DD as the difference of $NumDays and $cumDays[$i]", 1, $currentRoutine); 

    $Month = $monthName[$MM];

    # sort out the day suffix .....
    if ( length($DD) > 1 ) {
      $Last2Digit = substr($DD, length($DD) -2,2);
    }
    else {
      $Last2Digit = $DD;
    }

    $LastDigit = substr($DD, length($DD) -1,1);

    if    ($Last2Digit == 11) { $Suff = "th"; }
    elsif ($Last2Digit == 12) { $Suff = "th"; }
    elsif ($Last2Digit == 13) { $Suff = "th"; }
    elsif ($LastDigit == 1)   { $Suff = "st"; }
    elsif ($LastDigit == 2)   { $Suff = "nd"; }
    elsif ($LastDigit == 3)   { $Suff = "rd"; }
    else                      { $Suff = "th"; }

    $Year = substr("0" . $Year, length($Year)-1,2);
    $MM = substr("0" . $MM, length($MM)-1,2);
    $DD = substr("0" . $DD, length($DD)-1,2);

    if ($DD == 1) { $BOM = "Y" ; }
    if ($DD == $monthDays[$MM]) {
      $EOM = "Y";
      if ($MM == 12) {
        $EOY = "Y";
      }
      if ($MM == 6) {
        $EOFY = "Y";
      }
    }

    # work out the day of the week
    $tmp = ($HoldDays+5+$dateAdjust) % 7;
    $DOW = $DOWliterals[$tmp];

    displayDebug( "Date is $DD$Suff of $Month, $Century$Year (NumDays=$HoldDays)", 1, $currentRoutine); 
    return ($DD,$MM,$Century . $Year,$Suff,$Month,$HoldDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,'');

  }
  else { # a date of the formet DATE: or DATE= was provided $Date holds that value

    displayDebug( "Processing gregorian date of $Date", 1, $currentRoutine); 

    $EDD = substr($Date,6,2);
    $EMM = substr($Date,4,2);
    $EYY = substr($Date,0,4);
    $Rem = $EYY % 4;
    if ( ($EMM > 12) || ($EMM < 1) ) {
      $RetMSG = "Supplied date has an invalid month value : $EMM\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
      return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
    }
    if ( $EMM == 2 ) {
      if ( ($EDD < 1) || ($EDD >29) ) {
        $RetMSG = "Supplied date has an invalid day value : $EDD (Month = $EMM -1)\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
      elsif ( ($EDD == 29) && ($Rem != 0) ) {
        $RetMSG = "Supplied date has an invalid day value : $EDD (Month = $EMM -2)\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }
    elsif ( ($EMM == 9) || ($EMM == 4) || ($EMM ==6) || ($EMM == 11) ) {
      if ( ($EDD < 1) || ($EDD > 30) ) {
        $RetMSG = "Supplied date has an invalid day value : $EDD (Month = $EMM -3)\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }
    else {
      if ( ($EDD < 1) || ($EDD > 31) ) {
        $RetMSG = "Supplied date has an invalid day value : $EDD (Month = $EMM -4)\nUsage: $0 [DATE:yyyymmdd | DATE=yyyymmdd | numdays] [BASE:yyyy | BASE=yyyy]\n";
        return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,$RetMSG);
      }
    }

    $Year = "$BaseCentury$BaseYear";
    $NumDays = 0;
    while ( $Year != $EYY ) {
      $Rem = $Year % 4;
      if ( $Rem == 0 ) {
        if ( ($Year % 400) == 0) {
          $LeapYear = "No";
          $DaysInYear = 365;
        }
        else {
          $LeapYear = "Yes";
          $DaysInYear = 366;
        }
      }
      else {
        $LeapYear = "No";
        $DaysInYear = 365;
      }
     $NumDays = $NumDays + $DaysInYear;
     displayDebug( "NumDays=$NumDays Year=$Year LeapYear=$LeapYear Days in Year=$DaysInYear", 1, $currentRoutine); 
     $Year = $Year + 1;
    }
    $Rem = $EYY % 4;
    $AddBit = 0;
    if ( $Rem == 0 ) {
      $Rem2 = $EYY % 400;
      if ($Rem2 != 0) {
        $AddBit = 1;
      }
    }

    if ($AddBit == 1) { # adjust Feb days .....
      $monthDays[2] = $monthDays[2] + 1;
    }

    $i = 2;
    $cumDays[0] = 0;
    $cumDays[1] = 0;
    for ($i ; $i < 13 ; $i++ ) {
      $lastMonth = $i - 1;
      $cumDays[$i] = $cumDays[$lastMonth] + $monthDays[$lastMonth];
    }

    for ( my $k = 0 ; $k <= $#cumDays ; $k++ ) { displayDebug( "Cummlative month $k: $cumDays[$k]", 1, $currentRoutine); }

    $Month = $monthName[$EMM];
    $NumDays = $NumDays + $cumDays[$EMM] + $EDD;
    displayDebug( "Total days to beginning of this month: $cumDays[$EMM], days this month: $EDD", 1, $currentRoutine); 

    if ($EDD == 1) { $BOM = "Y" ;}
    if ($EDD == $monthDays[$EMM]) {
      $EOM = "Y";
      if ($EMM == 12) {
        $EOY = "Y";
      }
      if ($EMM == 6) {
        $EOFY = "Y";
      }
    }

    if ( length($EDD) > 1 ) {
      $Last2Digit = substr($EDD, length($EDD) -2,2);
    }
    else {
      $Last2Digit = $EDD;
    }

    $LastDigit = substr($EDD, length($EDD) -1,1);

    if    ($Last2Digit == 11) { $Suff = "th"; }
    elsif ($Last2Digit == 12) { $Suff = "th"; }
    elsif ($Last2Digit == 13) { $Suff = "th"; }
    elsif ($LastDigit == 1)   { $Suff = "st"; }
    elsif ($LastDigit == 2)   { $Suff = "nd"; }
    elsif ($LastDigit == 3)   { $Suff = "rd"; }
    else                      { $Suff = "th"; }

    $tmp = ($NumDays+5) % 7;
    $DOW = $DOWliterals[$tmp];

    displayDebug( "Date of $Date ($EDD$Suff of $Month, $EYY) has a value of $NumDays", 1, $currentRoutine); 
    return ($EDD,$EMM,$EYY,$Suff,$Month,$NumDays,$BaseDate,$EOM,$EOY,$EOFY,$BOM,$DOW,'');
  }
} # end of myDate

# -----------------------------------------------------------------
# processDirectory - function to traverse a directory tree
# -----------------------------------------------------------------

sub processDirectory { # routine to process a directory entry

  my $directory = shift;
  my $depth = shift;
  my $dirProc = shift;
  my $fileProc = shift;
  
  $depth++;
  
  if ( ($maxDepth == -1 ) || ($depth <= $maxDepth ) ) { 
  
    opendir(my $dh, $directory) || die;
    while(readdir $dh) {
  
      if ( ($_ eq '.') || ($_ eq '..') ) { next; } # skip directory elememnts . and ..
      if ( -l "$directory/$_" )  { next; }         # skip symlinks 
  
      if ( -d "$directory/$_" )  {                 # process the directory entry
        if ( defined($dirProc) ) {                 # if a subroutine has been passed 
          $dirProc -> ("$directory/$_",$depth);    # call the passed subroutine
        }
        processDirectory("$directory/$_", $depth,$dirProc,$fileProc);   # recursively call this routine rto process other directories
        $dirCnt ++;
      }
      else {                                       # it is a file
        if ( defined($fileProc) ) {                # if a subroutine has been passed 
          $fileProc -> ("$directory/$_",$depth);   # call the passed subroutine
        }
        $fileCnt++;
      }
    }
    closedir $dh; 
  }
  
  $depth--;
  
} # end of processDirectory

# -----------------------------------------------------------------
# localDateTime - convert a seconds since the epoch value to a local date/time
# -----------------------------------------------------------------

sub localDateTime {
  
  my $inDate = shift;
  
  my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = localtime $inDate;  # convert it
  
  $day = substr("0" . $day, length($day)-1,2);       # pad the day number to 2 digits
  $mon = $mon + 1;                                   # adjust the month value
  $mon = substr("0" . $mon, length($mon)-1,2);       # pad the month value to 2 digits
  $hour = substr("0" . $hour, length($hour)-1,2);       # pad the day number to 2 digits
  $min = substr("0" . $min, length($min)-1,2);       # pad the day number to 2 digits
  $sec = substr("0" . $sec, length($sec)-1,2);       # pad the day number to 2 digits
  if ( $year < 70) {                                    # epoch is at 1/1/1970 so dont let the date be any earlier
    $year = "70";
    $mon = "01";
    $day = "01";
  }
  my $yyyy_mm_dd = (1900 + $year) . '-' . $mon . '-' . $day;
  return ($yyyy_mm_dd . ' ' . $hour . ':' . $min . ':' . $sec);
} # end of localDateTime

# -----------------------------------------------------------------
# convertToTimestamp - convert a datetime to a standard timestamp format
# The script will attempt to figure out he format of the input date
# -----------------------------------------------------------------

sub convertToTimestamp {

  # Supported input formats:
  #      1. Sep 17, 2017 6:00:07 PM
  #
  # The output format will always be:
  #         2017.09.17 18:00:07
  
  my $inDate = shift;

  my ( $sec, $min, $hour, $day, $mon, $year);

  # check for quotes ..... (and remove them)

  if ( $inDate =~ /^".*"$/ ) {
    ($inDate) = ($inDate =~ /^"(.*)"$/);
  }

  my @part = split(" ", $inDate);

  if ( ! defined($part[4]) ) { # 4 parts not found - ignore call
    return '';
  }

  # process month
  if ( ! defined($monthNumber{$part[0]}) ) { # month not entered as the first parameter - return with no result
    return '';
  }
  else {
    $mon = $monthNumber{$part[0]};
  }
  
  my @tmp;
  # process the day .....
  if ( $part[1] =~ /,/ ) {
    @tmp = split(",", $part[1]); 
    $day = trim($tmp[0]); # just dropping the comma
  }
  else {
    $day = trim($part[1]);
  }
   
  # process the year .....
  $year = trim($part[2]); 

  # process the time .....
  @tmp = split(":", $part[3]); 
  $hour = trim($tmp[0]);
  $min = trim($tmp[1]);
  $sec = trim($tmp[2]);

  if ( ($part[4] eq 'PM') && ( $hour < 12 ) ) { $hour = $hour + 12; } # adjust to 24 hr clock
   
  # fill out numeric fields
  
  $day = substr("0" . $day, length($day)-1,2);       # pad the day number to 2 digits
  $mon = substr("0" . $mon, length($mon)-1,2);       # pad the month value to 2 digits
  $hour = substr("0" . $hour, length($hour)-1,2);    # pad the day number to 2 digits
  $min = substr("0" . $min, length($min)-1,2);       # pad the day number to 2 digits
  $sec = substr("0" . $sec, length($sec)-1,2);       # pad the day number to 2 digits
  
  return ($year . '.' . $mon . '.' . $day . ' ' . $hour . ':' . $min . ':' . $sec);
} # end of convertToTimestamp

1;

