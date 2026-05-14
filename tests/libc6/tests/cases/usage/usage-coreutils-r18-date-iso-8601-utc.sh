#!/usr/bin/env bash
# @testcase: usage-coreutils-r18-date-iso-8601-utc
# @title: date -u -d converts an epoch into a fixed ISO-8601 UTC string
# @description: Invokes date -u -d @1700000000 with -Iseconds and asserts the output equals "2023-11-14T22:13:20+00:00" — locking in libc-backed strftime emission for a known epoch in UTC.
# @timeout: 30
# @tags: usage, coreutils, date, strftime, r18
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(date -u -d @1700000000 -Iseconds)
want='2023-11-14T22:13:20+00:00'
[[ "$got" == "$want" ]] || {
    printf 'iso-8601 mismatch: want=%s got=%s\n' "$want" "$got" >&2
    exit 1
}
