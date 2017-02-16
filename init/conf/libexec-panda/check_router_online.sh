#!/bin/bash
# Check online routers for Hong.Shen

week="http://cloud.turboer.com/active_device_count?days=7"
month="http://cloud.turboer.com/active_device_count?days=30"

week_ol=$(/usr/bin/curl -s "$week")
month_ol=$(/usr/bin/curl -s "$month")

echo "Week online routers:${week_ol},Month online routers:${month_ol} | week_ol_r=${week_ol} month_ol_r=${month_ol}"
exit 0
