#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'old compressed payload\n' >"$tmpdir/payload"
bzip2 -kf "$tmpdir/payload"

printf 'new compressed payload\n' >"$tmpdir/payload"
bzip2 -kf "$tmpdir/payload"

printf 'new compressed payload\n' >"$tmpdir/expected"
bunzip2 -kc "$tmpdir/payload.bz2" >"$tmpdir/out"

cmp "$tmpdir/expected" "$tmpdir/out"
printf 'bzip2 force overwrite ok\n'
