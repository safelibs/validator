#!/usr/bin/env bash
# @testcase: usage-bzip2-r10-long-compress-flag
# @title: bzip2 --compress long flag is byte-equal to -z short flag
# @description: Compresses identical input twice via stdin, once with --compress and once with the short -z form, and verifies both .bz2 outputs are byte-identical to confirm the long-flag alias maps to the same operation.
# @timeout: 60
# @tags: usage, compression, long-flag
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'long-compress payload\n' >"$tmpdir/payload"

bzip2 --compress -c <"$tmpdir/payload" >"$tmpdir/long.bz2"
bzip2 -z -c       <"$tmpdir/payload" >"$tmpdir/short.bz2"

cmp "$tmpdir/long.bz2" "$tmpdir/short.bz2"

bzip2 -dc "$tmpdir/long.bz2" >"$tmpdir/round"
grep -Fq 'long-compress payload' "$tmpdir/round"
