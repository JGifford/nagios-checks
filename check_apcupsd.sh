#!/bin/sh
#
# check_apcupsd 2.6
# Nagios plugin to monitor APC Smart-UPSes and Back-UPSes using apcupsd.
##############################
# Download from Archive
# wget -O check_apcupsd.sh https://web.archive.org/web/20191001001655/http://martintoft.dk/software/check_apcupsd.txt
# sudo cp check_apcupsd.sh /usr/lib/nagios/plugins/.
# sudo chmod 755 /usr/lib/nagios/plugins/check_apcupsd.sh
##############################
#
# Website: http://martintoft.dk/?p=check_apcupsd
#
# Copyright (c) 2013 Stacy Millions <stacy@millions.ca> (improved error
# handling and support for battery voltage)
# Copyright (c) 2012 Patrick Reinhardt <pr@reinhardtweb.de> (more Back-UPS ES)
# Copyright (c) 2010 Ermanno Baschiera <ebaschiera@gmail.com> (Back-UPS ES)
# Copyright (C) 2010 Gabriele Tozzi <gabriele@tozzi.eu> (Back-UPS)
# Copyright (c) 2010 Gerold Gruber <Gerold.Gruber@edv2g.de> (perfdata)
# Copyright (c) 2008 Martin Toft <mt@martintoft.dk>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#
# Example configuration
#
# commands.cfg:
#
# define command {
#	 command_name check_apcupsd
#	 command_line $USER1$/check_apcupsd -w $ARG2$ -c $ARG3$ $ARG1$
#	 }
# 
# define command {
#	 command_name check_apcupsd_no_notify
#	 command_line $USER1$/check_apcupsd $ARG1$
#	 }
#
# ups1.cfg:
#
# define service {
#	 use generic-service
#	 host_name ups1
#	 service_description CHARGE
#	 check_command check_apcupsd!bcharge!95!50
#	 }
# 
# define service {
#	 use generic-service
#	 host_name ups1
#	 service_description BATT VOLTAGE
#	 check_command check_apcupsd!battv!95!85
#	 }
# 
# define service {
#	 use generic-service
#	 host_name ups1
#	 service_description TEMP
#	 check_command check_apcupsd!itemp!35!40
#	 }
# 
# define service {
#	 use generic-service
#	 host_name ups1
#	 service_description LOAD
#	 check_command check_apcupsd!loadpct!70!85
#	 }
# 
# define service {
#	 use generic-service
#	 host_name ups1
#	 service_description TIMELEFT
#	 check_command check_apcupsd_no_notify!timeleft
#	 }

APCACCESS=/sbin/apcaccess

#set default values
EXITVALUE=3
STATUS=UNKNOWN

CHARGEWARN=95
CHARGECRIT=50
TEMPWARN=35
TEMPCRIT=40
LOADWARN=70
LOADCRIT=85
TIMEWARN=10
TIMECRIT=5

usage()
{
	echo "usage: check_apcupsd [-c critical_value] [-h hostname] [-p port]"
	echo -n "		     [-w warning_value] "
	echo "<bcharge|battv|itemp|loadpct|timeleft|linefail|battstat|status>"
	echo
	echo "hostname and port defaults to localhost and 3551, respectively."
	echo
	echo "checks:"
	echo "    bcharge  = battery charge, measured in percent."
	echo "    battv    = battery voltage, measured in volts."
	echo "               critical_value and warning_value are given as a"
	echo "               percentage of the battery's nominal voltage"
	echo "    itemp    = internal temperature, measured in degree Celcius."
	echo "    loadpct  = load percent, measured in percent (do'h!)."
	echo "    timeleft = time left with current battery charge and load,"
	echo "	       measured in minutes."
	echo "    linefail = Whether the line is OK or not (Back UPS only)"
	echo "    status   = Same as 'linefail' (Back UPS ES only - maybe others)"
	echo "    battstat = Whether the battery is OK or not (Back UPS only)"
	exit 3
}

HOSTNAME=localhost
PORT=3551

while getopts c:h:p:w: OPTNAME; do
	case "$OPTNAME" in
	h)
		HOSTNAME="$OPTARG"
		;;
	p)
		PORT="$OPTARG"
		;;
	w)
		WARNVAL="$OPTARG"
		;;
	c)
		CRITVAL="$OPTARG"
		;;
	*)
		usage
		;;
	esac
done

ARG="$@"
while [ $OPTIND -gt 1 ]; do
	ARG=`echo "$ARG" | sed 's/^[^ ][^ ]* *//'`
	OPTIND=$(($OPTIND-1))
done

if [ "$ARG" != "bcharge" -a "$ARG" != "battv" -a "$ARG" != "itemp" \
	-a "$ARG" != "loadpct" -a "$ARG" != "timeleft" -a "$ARG" != "linefail" \
	-a "$ARG" != "battstat" -a  "$ARG" != "status" ]; then
	usage
fi

if [ "`echo $PORT | grep '^[0-9][0-9]*$'`" = "" ]; then
	echo "Error: port must be a positive integer!"
	exit 3
fi

if [ "$WARNVAL" != "" -a "`echo $WARNVAL | grep '^[0-9][0-9]*$'`" = "" ]; then
	echo "Error: warning_value must be a positive integer!"
	exit 3
fi

if [ "$CRITVAL" != "" -a "`echo $CRITVAL | grep '^[0-9][0-9]*$'`" = "" ]; then
	echo "Error: critical_value must be a positive integer!"
	exit 3
fi

if [ "$WARNVAL" != "" -a "$CRITVAL" != "" ]; then
	if [ "$ARG" = "bcharge" -o "$ARG" = "battv" -o "$ARG" = "timeleft" ]; then
		if [ $WARNVAL -le $CRITVAL ]; then
			echo "Error: warning_value must be greater than critical_value!"
			exit 3
		fi
	else
		if [ $WARNVAL -ge $CRITVAL ]; then
			echo "Error: warning_value must be less than critical_value!"
			exit 3
		fi
	fi
fi

if [ ! -x "$APCACCESS" ]; then
	echo "Error: $APCACCESS must exist and be executable!"
	exit 3
fi

$APCACCESS status $HOSTNAME:$PORT > /dev/null
if [ $? -ne 0 ]; then
	# The error message from apcaccess will do fine.
	exit 3
fi

# Back UPS reports only an OK / ERR state
if [ "$ARG" != "linefail" -a "$ARG" != "battstat" -a "$ARG" != "status" ]; then
	VALUE=`$APCACCESS status $HOSTNAME:$PORT | grep -i ^$ARG | \
		sed 's/.*:  *\([0-9.][0-9.]*\)[^0-9.].*/\1/'`
	if [ -z "$VALUE" ]; then
		echo "UPS does not support $ARG"
		exit 3
	fi
	if [ "$VALUE" != "0" -a "$VALUE" != "0.0" ]; then
		VALUE=`echo $VALUE | sed 's/^0*//'`
	fi
	ROUNDED=`echo $VALUE | sed 's/\..*//'`
else
	VALUE=`$APCACCESS status $HOSTNAME:$PORT | grep -i ^$ARG | \
		sed 's/.*:  *\([A-Z]*\).*/\1/'`
#echo "$VALUE"
	if [ -z "$VALUE" ]; then
		echo "UPS does not support $ARG"
		exit 3
	fi
	if [ "$VALUE" = "ONLINE" ]; then
		ROUNDED=1
	else
		ROUNDED=0
	fi
fi

case "$ARG" in
linefail)
	if [ $ROUNDED -gt 0 ]; then
		STATUS="OK"
		EXITVALUE=0
	else
		STATUS="CRITICAL"
		EXITVALUE=2
	fi
	echo "${STATUS} - Power Line: ${VALUE}|'Power Line'=${ROUNDED}"
	;;
status)
        if [ $ROUNDED -gt 0 ]; then
                STATUS="OK"
                EXITVALUE=0
        else
                STATUS="CRITICAL"
                EXITVALUE=2
        fi
        echo "${STATUS} - Power Line: ${VALUE}|'Power Line'=${ROUNDED}"
        ;;
battstat)
        if [ $ROUNDED -gt 0 ]; then
                STATUS="OK"
                EXITVALUE=0
        else
                STATUS="CRITICAL"
                EXITVALUE=2
        fi
        echo "${STATUS} - Battery Status: ${VALUE}|'Battery Status'=${ROUNDED}"
        ;;
bcharge)
	if [ "$CRITVAL" = "" ]; then
		CRITVAL=$CHARGECRIT
	fi
	if [ "$WARNVAL" = "" ]; then
		WARNVAL=$CHARGEWARN
	fi
	if [ $ROUNDED -lt $CRITVAL ]; then
		STATUS="CRITICAL"
		EXITVALUE=2
	elif [ $ROUNDED -lt $WARNVAL ]; then
		STATUS="WARNING"
		EXITVALUE=1
	else
		STATUS="OK"
		EXITVALUE=0
	fi
	echo "${STATUS} - Battery Charge: ${VALUE}%|'Battery Charge'=${VALUE}%;$WARNVAL:;$CRITVAL:;;"
	;;
battv)
	# get nominal battery voltage
	NOMVAL=`$APCACCESS status $HOSTNAME:$PORT | grep -i '^NOMBATTV' | \
		sed 's/.*:  *\([0-9.]*\).*$/\1/'`

	if [ -z "$NOMVAL" ]; then
		if [ -n "$WARNVAL" -o -n "$CRITVAL" ]; then
			echo UPS does not support NOMBATTV
			exit 3
		fi
	else
		#calculate percentage of nominal value BATTV is
		PVAL=`dc <<-__EOF__
			6k
			100
			${VALUE}
			${NOMVAL}/*p
		__EOF__`

		# round the percentage of nominal
		ROUNDED=`echo $PVAL | sed 's/\..*//'`

		STATUS="OK"
		EXITVALUE=0
		if [ "$WARNVAL" != "" ]; then
			if [ $ROUNDED -lt $WARNVAL ]; then
				STATUS="WARNING"
				EXITVALUE=1
			fi
		fi
		if [ "$CRITVAL" != "" ]; then
			if [ $ROUNDED -lt $CRITVAL ]; then
				STATUS="CRITICAL"
				EXITVALUE=2
			fi
		fi
	fi
	echo "${STATUS} - Battery Voltage: ${VALUE}V|'Battery Voltage'=${VALUE}V;$WARNVAL:;$CRITVAL:;;"
	;;
itemp)
	if [ "$CRITVAL" = "" ]; then
		CRITVAL=$TEMPCRIT
	fi
	if [ "$WARNVAL" = "" ]; then
		WARNVAL=$TEMPWARN
	fi
	if [ $ROUNDED -ge $CRITVAL ]; then
		STATUS="CRITICAL"
		EXITVALUE=2
	elif [ $ROUNDED -ge $WARNVAL ]; then
		STATUS="WARNING"
		EXITVALUE=1
	else
		STATUS="OK"
		EXITVALUE=0
	fi
	echo "${STATUS} - Internal Temperature: $VALUE C|'Battery Temperature'=${VALUE}C;$WARNVAL;$CRITVAL;;"
	;;
loadpct)
	if [ "$CRITVAL" = "" ]; then
		CRITVAL=$LOADCRIT
	fi
	if [ "$WARNVAL" = "" ]; then
		WARNVAL=$LOADWARN
	fi
	if [ $ROUNDED -ge $CRITVAL ]; then
		STATUS="CRITICAL"
		EXITVALUE=2
	elif [ $ROUNDED -ge $WARNVAL ]; then
		STATUS="WARNING"
		EXITVALUE=1
	else
		STATUS="OK"
		EXITVALUE=0
	fi
	echo "${STATUS} - Load: ${VALUE}%|'UPS Load'=${VALUE}%;$WARNVAL;$CRITVAL;;"
	;;
timeleft)
	if [ "$CRITVAL" = "" ]; then
		CRITVAL=$TIMECRIT
	fi
	if [ "$WARNVAL" = "" ]; then
		WARNVAL=$TIMEWARN
	fi
	if [ $ROUNDED -lt $CRITVAL ]; then
		STATUS="CRITICAL"
		EXITVALUE=2
	elif [ $ROUNDED -lt $WARNVAL ]; then
		STATUS="WARNING"
		EXITVALUE=1
	else
		STATUS="OK"
		EXITVALUE=0
	fi
	echo "${STATUS} - Time Left: $VALUE Minutes|'minutes left'=${VALUE};$WARNVAL:;$CRITVAL:;;"
	;;
esac

exit $EXITVALUE
