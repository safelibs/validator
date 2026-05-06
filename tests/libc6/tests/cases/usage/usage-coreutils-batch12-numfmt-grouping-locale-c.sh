#!/usr/bin/env bash
# @testcase: usage-coreutils-batch12-numfmt-grouping-locale-c
# @title: numfmt --grouping under LC_ALL=C is a no-op
# @description: Runs numfmt --grouping on a large integer with LC_ALL=C and verifies no thousands separators are inserted (libc nl_langinfo path under POSIX locale).
# @timeout: 60
# @tags: usage, coreutils, locale
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C numfmt --grouping 1234567890 >"$tmpdir/out.txt"
got=$(tr -d '\n' <"$tmpdir/out.txt")
[[ "$got" == "1234567890" ]]
