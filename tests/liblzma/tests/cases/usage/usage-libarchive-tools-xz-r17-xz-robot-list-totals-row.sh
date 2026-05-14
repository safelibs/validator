#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-xz-robot-list-totals-row
# @title: xz --robot --list emits a totals row
# @description: Compresses a payload, runs xz --robot --list on it, and asserts the machine-readable robot listing includes a "totals" row, pinning the documented robot-mode listing schema.
# @timeout: 60
# @tags: usage, xz, list, robot, totals
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r17 robot totals payload\n' >"$tmpdir/in.txt"
xz -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz --robot --list "$tmpdir/out.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'totals'
