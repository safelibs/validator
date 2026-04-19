#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first\n' >"$tmpdir/one"; printf 'second\n' >"$tmpdir/two"; bzip2 -c "$tmpdir/one" >"$tmpdir/one.bz2"; bzip2 -c "$tmpdir/two" >"$tmpdir/two.bz2"; cat "$tmpdir/one.bz2" "$tmpdir/two.bz2" >"$tmpdir/both.bz2"; bunzip2 -c "$tmpdir/both.bz2" | tee "$tmpdir/out"; cmp <(printf 'first\nsecond\n') "$tmpdir/out"
