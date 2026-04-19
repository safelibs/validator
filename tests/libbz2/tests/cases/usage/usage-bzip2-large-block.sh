#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    yes payload | head -n 200 >"$tmpdir/in.txt"
bzip2 -9 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"
bzip2 -dc "$tmpdir/in.bz2" | wc -l