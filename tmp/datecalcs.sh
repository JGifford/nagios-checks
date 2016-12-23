#!/bin/bash

flexlm_date="17-jul-2017"
flexlm_date="17-jan-2017"
flexlm_date="22-jan-2017"
date_suffix="23:59:59"
date_expire=$flexlm_date" "$date_suffix
date_today=$(date "+%d-%b-%Y")" "$date_suffix
seconds_30_days=2592000
seconds_60_days=5184000
seconds_in_day=86400

epoch_expire=$(date --date="$date_expire" "+%s")
epoch_today=$(date --date="$date_today" "+%s")

echo "epoch expire: " $epoch_expire
echo "epoch today:  " $epoch_today

difference=`expr $epoch_expire - $epoch_today`
echo $seconds_30_days": "$difference
echo $seconds_60_days": "$difference

days_remaining=$(($difference / $seconds_in_day))

if [ "$difference" -le "$seconds_30_days" ]
then
    echo "less than 30 days ("$days_remaining")"
else
    if [ "$difference" -le "$seconds_60_days" ]
    then
	echo "less than 60 days ("$days_remaining")"
    else
	echo "everything is fine ("$days_remaining")"
    fi
fi

