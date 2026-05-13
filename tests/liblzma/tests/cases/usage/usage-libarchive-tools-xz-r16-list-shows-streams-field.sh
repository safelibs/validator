#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-list-shows-streams-field
# @title: xz -l verbose listing prints a Streams field row
# @description: Compresses a payload, runs xz -l --verbose on the output, and asserts the captured listing contains the literal "Streams" label, distinct from earlier rounds that pinned the Name row or the totals row only.
# @timeout: 60
# @tags: usage, xz, list, streams
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r16 list streams field payload\n' >"$tmpdir/in.txt"
xz -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz -l --verbose "$tmpdir/out.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'Streams'
