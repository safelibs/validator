#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'bzip2 source case\n' >"$tmpdir/plain"; bzip2 -c "$tmpdir/plain" >"$tmpdir/plain.bz2"; bunzip2 -c "$tmpdir/plain.bz2" >"$tmpdir/out"; cmp "$tmpdir/plain" "$tmpdir/out"; ls -l "$tmpdir/plain.bz2"
