#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'pipe payload\n' | bzip2 -c | bzip2 -dc | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'pipe payload'