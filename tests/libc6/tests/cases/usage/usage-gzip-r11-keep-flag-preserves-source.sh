#!/usr/bin/env bash
# @testcase: usage-gzip-r11-keep-flag-preserves-source
# @title: gzip --keep retains the original input file alongside the gz
# @description: Compresses a fixture file with gzip --keep and verifies both the original input file and the new .gz file exist after compression exercising gzip libc-backed file open and rename suppression behavior.
# @timeout: 60
# @tags: usage, gzip, keep
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'libc6 keep flag\n' >"$tmpdir/input.txt"
LC_ALL=C gzip --keep "$tmpdir/input.txt"
[[ -f "$tmpdir/input.txt" ]]
[[ -f "$tmpdir/input.txt.gz" ]]
LC_ALL=C gunzip -c "$tmpdir/input.txt.gz" >"$tmpdir/decoded.txt"
LC_ALL=C diff -u "$tmpdir/input.txt" "$tmpdir/decoded.txt"
