#!/usr/bin/env bash
# @testcase: usage-coreutils-printf-padding
# @title: coreutils printf width padding
# @description: Formats integers with /usr/bin/printf using zero-pad and right-align width specifiers under LC_ALL=C and verifies the resulting columns.
# @timeout: 60
# @tags: usage, coreutils, locale
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-printf-padding"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C /usr/bin/printf '%05d|%5d|%-5d.\n' 42 42 42 >"$tmpdir/out"
printf '00042|   42|42   .\n' >"$tmpdir/expected"
cmp "$tmpdir/expected" "$tmpdir/out"
