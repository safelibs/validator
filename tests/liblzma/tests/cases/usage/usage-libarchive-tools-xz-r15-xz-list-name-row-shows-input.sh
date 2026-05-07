#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-xz-list-name-row-shows-input
# @title: xz --robot --list emits a "name" row whose second column is the input path
# @description: Compresses a payload and runs "xz --robot --list" on the output, then asserts the line beginning with "name" reports the input filename in its tab-separated path field — pinning a different robot-mode column from the r14 robot-info-fields case (which only checks row presence) and the r14 sha256-list-column case (which only checks the totals row).
# @timeout: 60
# @tags: usage, xz, robot, list, name
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r15 robot list name row payload alpha beta\n' >"$tmpdir/in.txt"
xz -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz --robot --list "$tmpdir/out.xz" >"$tmpdir/list.txt"

# The "name" row is "name\t<path>".
name_path=$(awk '$1=="name"{print $2}' "$tmpdir/list.txt")
test "$name_path" = "$tmpdir/out.xz"
