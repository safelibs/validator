#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    bzip2 --version 2>&1 | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'bzip2'