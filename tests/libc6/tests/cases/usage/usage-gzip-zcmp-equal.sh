#!/usr/bin/env bash
# @testcase: usage-gzip-zcmp-equal
# @title: gzip zcmp compares two .gz files
# @description: Uses zcmp to compare two gzip-compressed files with identical and differing payloads, verifying exit codes and diff output.
# @timeout: 180
# @tags: usage, gzip, archive
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-zcmp-equal"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'shared payload line\nsecond line\n' >"$tmpdir/a.txt"
cp "$tmpdir/a.txt" "$tmpdir/b.txt"
printf 'shared payload line\ndiverged line\n' >"$tmpdir/c.txt"

gzip -k "$tmpdir/a.txt"
gzip -k "$tmpdir/b.txt"
gzip -k "$tmpdir/c.txt"

# Equal payloads compress to bit-identical or differing streams but should
# decompress equal -- zcmp must report no difference and exit 0.
zcmp "$tmpdir/a.txt.gz" "$tmpdir/b.txt.gz"

# Differing payloads must produce a non-zero exit and a diff line on stdout.
set +e
zcmp "$tmpdir/a.txt.gz" "$tmpdir/c.txt.gz" >"$tmpdir/diff" 2>&1
status=$?
set -e
test "$status" -ne 0
validator_assert_contains "$tmpdir/diff" 'differ'
