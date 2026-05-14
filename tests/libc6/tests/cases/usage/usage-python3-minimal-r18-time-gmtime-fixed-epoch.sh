#!/usr/bin/env bash
# @testcase: usage-python3-minimal-r18-time-gmtime-fixed-epoch
# @title: python3 time.gmtime decomposes a fixed epoch into a known UTC tuple
# @description: Invokes python3 -c with time.gmtime(1700000000) and asserts the year/month/day/hour/minute/second fields equal 2023/11/14/22/13/20 — locking in libc-backed gmtime for a deterministic epoch.
# @timeout: 30
# @tags: usage, python3-minimal, time, gmtime, r18
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(python3 -c '
import time
t = time.gmtime(1700000000)
print(f"{t.tm_year}-{t.tm_mon:02d}-{t.tm_mday:02d}T{t.tm_hour:02d}:{t.tm_min:02d}:{t.tm_sec:02d}")
')
want='2023-11-14T22:13:20'
[[ "$got" == "$want" ]] || {
    printf 'gmtime mismatch: want=%s got=%s\n' "$want" "$got" >&2
    exit 1
}
