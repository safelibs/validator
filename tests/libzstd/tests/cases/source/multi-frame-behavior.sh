#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'frame one\n' >"$tmpdir/one"; printf 'frame two\n' >"$tmpdir/two"; zstd -q -c "$tmpdir/one" >"$tmpdir/one.zst"; zstd -q -c "$tmpdir/two" >"$tmpdir/two.zst"; cat "$tmpdir/one.zst" "$tmpdir/two.zst" >"$tmpdir/both.zst"; zstd -q -dc "$tmpdir/both.zst" | tee "$tmpdir/out"; cmp <(printf 'frame one\nframe two\n') "$tmpdir/out"
