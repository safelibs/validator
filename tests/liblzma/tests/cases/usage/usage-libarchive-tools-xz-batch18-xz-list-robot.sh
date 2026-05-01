#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-xz-list-robot
# @title: xz --list --robot machine-readable output
# @description: Compresses a bsdtar-produced tar with xz, runs xz --list --robot on it, and validates the machine-readable output begins with a totals/file/stream record set covering exactly one stream and one block.
# @timeout: 180
# @tags: usage, archive, xz, robot, list
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'robot list payload one\n' >"$tmpdir/src/alpha.txt"
printf 'robot list payload two\n' >"$tmpdir/src/beta.txt"

bsdtar -cf "$tmpdir/plain.tar" -C "$tmpdir/src" alpha.txt beta.txt
xz -z -c "$tmpdir/plain.tar" >"$tmpdir/plain.tar.xz"

magic_hex=$(head -c 6 "$tmpdir/plain.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz --list --robot "$tmpdir/plain.tar.xz" >"$tmpdir/list.tsv"

# Robot output should include a "name" and a "totals" record line.
validator_assert_contains "$tmpdir/list.tsv" 'name'
validator_assert_contains "$tmpdir/list.tsv" 'totals'

# A single-file/single-stream archive: stream count == 1 in the totals row.
totals_line=$(grep '^totals' "$tmpdir/list.tsv" | head -n1)
streams=$(printf '%s\n' "$totals_line" | awk '{print $2}')
blocks=$(printf '%s\n' "$totals_line" | awk '{print $3}')
test "$streams" = "1"
test "$blocks" = "1"
