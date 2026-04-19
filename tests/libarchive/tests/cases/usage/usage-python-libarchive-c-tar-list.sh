#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'alpha\n' >"$tmpdir/in/alpha.txt"
printf 'beta\n' >"$tmpdir/in/beta.txt"
bsdtar -cf "$tmpdir/a.tar" -C "$tmpdir/in" .
bsdtar -tf "$tmpdir/a.tar" | tee "$tmpdir/list"
bsdtar -xf "$tmpdir/a.tar" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/alpha.txt" 'alpha'