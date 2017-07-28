#!/bin/bash
#
# Parses through development log to get
# performance numbers for WMS dispatching
#

# Grab all ms values, then use awk to calculate average
cat ./log/development.log | grep "WMS Dispatch" | ruby -ne 'print "#{$_[/(\d+\.\d+)ms/, 1]}\n"' | awk '{ total += $1; count++ } END { print total/count }'