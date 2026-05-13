#!/usr/bin/env bash
# @testcase: usage-gio-r16-move-then-info-on-destination
# @title: gio move retires the source path and yields a queryable destination
# @description: Writes a payload to source.txt, runs gio move source.txt dest.txt, then asserts the source path is gone and gio info --attributes=standard::size on the destination reports the expected byte count, exercising the move-then-query path.
# @timeout: 60
# @tags: usage, gio, move, info
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

payload='r16-gio-move-payload'
printf '%s' "$payload" >"$tmpdir/source.txt"
expected_size=$(stat -c '%s' "$tmpdir/source.txt")

gio move "$tmpdir/source.txt" "$tmpdir/dest.txt"

if [[ -e "$tmpdir/source.txt" ]]; then
    printf 'gio move did not remove source\n' >&2
    exit 1
fi

validator_require_file "$tmpdir/dest.txt"
gio info --attributes='standard::size' "$tmpdir/dest.txt" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" "standard::size: $expected_size"
