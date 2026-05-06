#!/usr/bin/env bash
# @testcase: usage-python3-minimal-r11-strftime-utc-fixed
# @title: python3 strftime formats a fixed UTC epoch via libc strftime
# @description: Calls time.strftime with a known UTC struct_time built from a fixed epoch and verifies the formatted ISO string matches the expected value exercising python3 wrapping libc strftime.
# @timeout: 60
# @tags: usage, python3, strftime
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
got=$(LC_ALL=C python3 -c '
import time
t = time.gmtime(1700000000)
print(time.strftime("%Y-%m-%dT%H:%M:%SZ", t))
')
[[ "$got" == "2023-11-14T22:13:20Z" ]]
