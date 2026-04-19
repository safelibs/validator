#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'alpha beta\n' >"$tmpdir/in.txt"
bzip2 -k "$tmpdir/in.txt"
bzip2 -dc "$tmpdir/in.txt.bz2" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha beta'