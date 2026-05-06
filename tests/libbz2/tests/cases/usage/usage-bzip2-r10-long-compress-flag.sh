#!/usr/bin/env bash
# @testcase: usage-bzip2-r10-long-compress-flag
# @title: bzip2 --compress long flag forces compression even on .bz2 input
# @description: Names a file with a .bz2 suffix so the default action would refuse, then runs bzip2 --compress --force to verify the long --compress flag still triggers compression and produces a doubly-encoded .bz2.bz2 file.
# @timeout: 60
# @tags: usage, compression, long-flag
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'long-compress payload\n' >"$tmpdir/raw"
bzip2 "$tmpdir/raw"

# Now $tmpdir/raw.bz2 exists. Compress it again explicitly with --compress.
bzip2 --compress --force "$tmpdir/raw.bz2"

[[ -f "$tmpdir/raw.bz2.bz2" ]]
head -c 3 "$tmpdir/raw.bz2.bz2" | od -An -c | tr -d ' \n' | grep -q 'BZh'

bzip2 -dc "$tmpdir/raw.bz2.bz2" >"$tmpdir/inner.bz2"
bzip2 -dc "$tmpdir/inner.bz2" >"$tmpdir/round"
grep -Fq 'long-compress payload' "$tmpdir/round"
