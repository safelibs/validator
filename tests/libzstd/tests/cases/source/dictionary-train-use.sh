#!/usr/bin/env bash
# @testcase: dictionary-train-use
# @title: zstd dictionary train use
# @description: Trains a small dictionary, compresses with it, and decompresses with it.
# @timeout: 120
# @tags: cli, dictionary

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/samples"
for i in $(seq 1 160); do
  for j in $(seq 1 16); do
    printf 'record-%03d common-prefix common-suffix field-%02d value-%03d repeated-token\n' "$i" "$j" "$i"
  done >"$tmpdir/samples/s$i"
done
zstd --train "$tmpdir"/samples/* -o "$tmpdir/dict" --maxdict=1024 | tee "$tmpdir/train"
printf 'record-999 common-prefix common-suffix field-01 value-999 repeated-token\n' >"$tmpdir/msg"
zstd -q -D "$tmpdir/dict" -c "$tmpdir/msg" >"$tmpdir/msg.zst"
zstd -q -D "$tmpdir/dict" -dc "$tmpdir/msg.zst" >"$tmpdir/out"
cmp "$tmpdir/msg" "$tmpdir/out"
ls -l "$tmpdir/dict" "$tmpdir/msg.zst"
