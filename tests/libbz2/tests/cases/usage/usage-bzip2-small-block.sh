#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'small block payload\n' >"$tmpdir/in.txt"
bzip2 -1 -c "$tmpdir/in.txt" | bzip2 -dc