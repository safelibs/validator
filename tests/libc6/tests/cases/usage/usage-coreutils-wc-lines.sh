#!/usr/bin/env bash
# @testcase: usage-coreutils-wc-lines
# @title: coreutils counts lines
# @description: Counts lines in a text file with wc and verifies the reported total.
# @timeout: 180
# @tags: usage, cli
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-wc-lines"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
wc -l "$tmpdir/in.txt" >"$tmpdir/out"
grep -Eq '3[[:space:]]+' "$tmpdir/out"
