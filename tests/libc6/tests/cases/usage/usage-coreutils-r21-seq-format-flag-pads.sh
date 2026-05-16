#!/usr/bin/env bash
# @testcase: usage-coreutils-r21-seq-format-flag-pads
# @title: seq -f "%03g" 1 3 emits zero-padded "001", "002", "003"
# @description: Runs seq -f "%03g" 1 3 and asserts the three output lines equal exactly "001", "002", "003" - locking in seq's printf-style format flag rendering distinct from prior seq-free coreutils numeric tests.
# @timeout: 30
# @tags: usage, coreutils, seq, format, r21
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(seq -f '%03g' 1 3)
expected=$'001\n002\n003'
[[ "$got" == "$expected" ]] || {
    printf 'expected %q, got %q\n' "$expected" "$got" >&2
    exit 1
}
