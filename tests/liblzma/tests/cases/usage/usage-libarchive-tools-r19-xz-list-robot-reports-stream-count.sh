#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-xz-list-robot-reports-stream-count
# @title: xz --list --robot reports exactly one stream for a single-stream .xz file
# @description: Compresses a payload to a single-stream .xz then runs xz --list --robot and asserts the totals line reports streams=1, pinning the machine-readable listing semantics for single-stream archives.
# @timeout: 60
# @tags: usage, xz, list, robot, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r19 xz list robot payload\n' >"$tmpdir/in.txt"
xz -c "$tmpdir/in.txt" >"$tmpdir/in.xz"

xz --list --robot "$tmpdir/in.xz" >"$tmpdir/listing.txt"
validator_require_file "$tmpdir/listing.txt"

# robot totals line is: totals <streams> <blocks> <compressed> <uncompressed> ...
awk '/^totals/{ if ($2 == "1") found=1 } END { exit (found ? 0 : 1) }' "$tmpdir/listing.txt"
