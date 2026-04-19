#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/samples"; for i in $(seq 1 80); do printf 'record-%03d common-prefix common-suffix %03d\n' "$i" "$i" >"$tmpdir/samples/s$i"; done; zstd --train "$tmpdir"/samples/* -o "$tmpdir/dict" --maxdict=2048 | tee "$tmpdir/train"; printf 'record-999 common-prefix common-suffix 999\n' >"$tmpdir/msg"; zstd -q -D "$tmpdir/dict" -c "$tmpdir/msg" >"$tmpdir/msg.zst"; zstd -q -D "$tmpdir/dict" -dc "$tmpdir/msg.zst" >"$tmpdir/out"; cmp "$tmpdir/msg" "$tmpdir/out"; ls -l "$tmpdir/dict" "$tmpdir/msg.zst"
