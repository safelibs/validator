#!/usr/bin/env bash
# @testcase: usage-coreutils-r11-od-canonical-bytes
# @title: coreutils od -An -tx1 dumps raw bytes via libc fread loop
# @description: Pipes a known 5-byte ASCII string through od -An -tx1 -w16 and verifies the hex dump matches the expected ASCII byte values, exercising od's libc fread block-reading path.
# @timeout: 60
# @tags: usage, coreutils, od
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
got=$(printf 'abcde' | LC_ALL=C od -An -tx1 -w16 | tr -s ' ' | sed 's/^ //;s/ *$//')
[[ "$got" == "61 62 63 64 65" ]]
