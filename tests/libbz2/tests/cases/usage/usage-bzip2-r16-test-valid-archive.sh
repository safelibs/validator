#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-test-valid-archive
# @title: bzip2 -t returns 0 on a valid .bz2 archive
# @description: Compresses a payload, then runs bzip2 -t on the resulting archive and asserts the exit code is 0 — locking in the integrity-test path that distinguishes valid archives from truncated or corrupted ones.
# @timeout: 60
# @tags: usage, bzip2, test, integrity
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r16 test-valid archive payload\nwith two lines\n' >"$tmpdir/payload.txt"
bzip2 -c "$tmpdir/payload.txt" >"$tmpdir/payload.bz2"

bzip2 -t "$tmpdir/payload.bz2"
