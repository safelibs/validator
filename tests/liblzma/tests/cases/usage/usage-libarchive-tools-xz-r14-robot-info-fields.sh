#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r14-robot-info-fields
# @title: xz --robot --info reports machine-readable file/stream/totals rows
# @description: Compresses a payload, runs "xz --robot -vv --list" (machine-readable verbose info mode) and asserts the output contains the documented robot-mode rows: name, file, stream, block, summary, and totals.
# @timeout: 60
# @tags: usage, xz, robot, info
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'robot info payload alpha beta gamma\n' >"$tmpdir/in.txt"
xz -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz --robot -vv --list "$tmpdir/out.xz" >"$tmpdir/list.txt"

# Robot mode emits one row per kind, prefixed by the row name.
awk '{print $1}' "$tmpdir/list.txt" | sort -u >"$tmpdir/rows.txt"

grep -Fxq 'name'    "$tmpdir/rows.txt"
grep -Fxq 'file'    "$tmpdir/rows.txt"
grep -Fxq 'stream'  "$tmpdir/rows.txt"
grep -Fxq 'block'   "$tmpdir/rows.txt"
grep -Fxq 'summary' "$tmpdir/rows.txt"
grep -Fxq 'totals'  "$tmpdir/rows.txt"
