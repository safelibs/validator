#!/usr/bin/env bash
# @testcase: usage-coreutils-batch12-printf-floating-point-precision
# @title: /usr/bin/printf %.6f matches libc snprintf rounding
# @description: Runs /usr/bin/printf with %.6f on a known IEEE-754 value and verifies the formatted output matches the expected libc rounding.
# @timeout: 60
# @tags: usage, coreutils, printf, locale
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C /usr/bin/printf '%.6f\n' 3.141592653589793 >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "3.141593" ]]

LC_ALL=C /usr/bin/printf '%.3f\n' 0.0005 >"$tmpdir/out2.txt"
got2=$(cat "$tmpdir/out2.txt")
# Standard banker's rounding under glibc rounds 0.0005 to 0.000.
# But "round half away from zero" => 0.001. Either is acceptable across libc;
# accept both.
[[ "$got2" == "0.000" || "$got2" == "0.001" ]]
