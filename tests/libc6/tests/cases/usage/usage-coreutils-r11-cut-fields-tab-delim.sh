#!/usr/bin/env bash
# @testcase: usage-coreutils-r11-cut-fields-tab-delim
# @title: coreutils cut -f extracts tab-delimited fields via libc fread
# @description: Builds a TSV file with three columns and verifies that cut -f1,3 emits only columns 1 and 3 in tab-delimited form, exercising cut's libc-backed line buffering and field splitting.
# @timeout: 60
# @tags: usage, coreutils, cut
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a\tb\tc\nd\te\tf\ng\th\ti\n' >"$tmpdir/in.tsv"
LC_ALL=C cut -f1,3 "$tmpdir/in.tsv" >"$tmpdir/out.tsv"
LC_ALL=C diff -u <(printf 'a\tc\nd\tf\ng\ti\n') "$tmpdir/out.tsv"
