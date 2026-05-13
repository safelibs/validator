#!/usr/bin/env bash
# @testcase: usage-bash-r16-printf-percent-y-current-year-shape
# @title: bash printf "%(%Y)T" -1 prints a four-digit current-year-shaped string
# @description: Invokes bash's printf strftime conversion with -1 (now) using "%(%Y)T" and asserts the result is exactly four ASCII digits, locking in GNU printf's strftime format integration without committing to a specific year.
# @timeout: 30
# @tags: usage, bash, printf, strftime
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf '%(%Y)T' -1)
[[ "$out" =~ ^[0-9]{4}$ ]] || {
    printf 'expected 4-digit year, got %q\n' "$out" >&2
    exit 1
}
