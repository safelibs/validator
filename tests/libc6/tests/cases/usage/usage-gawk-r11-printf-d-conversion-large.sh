#!/usr/bin/env bash
# @testcase: usage-gawk-r11-printf-d-conversion-large
# @title: gawk printf %d formats large integers via libc snprintf
# @description: Uses awk BEGIN block printf %d on the value 2147483647 INT32 max and verifies the formatted string round-trips through libc snprintf without overflow truncation.
# @timeout: 60
# @tags: usage, gawk, printf
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
got=$(LC_ALL=C awk 'BEGIN { printf "%d\n", 2147483647 }')
[[ "$got" == "2147483647" ]]
