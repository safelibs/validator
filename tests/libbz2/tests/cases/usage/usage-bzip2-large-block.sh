#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    for i in $(seq 1 200); do
        printf 'payload %03d\n' "$i"
    done >"$tmpdir/in.txt"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
bzip2 -dc "$tmpdir/in.bz2" | wc -l
