#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

t="$VALIDATOR_SOURCE_ROOT/test/images/minisblack-1c-8b.tiff"; validator_require_file "$t"; tiffdump "$t" | tee "$tmpdir/dump"; grep -Ei 'ImageWidth|ImageLength' "$tmpdir/dump"
