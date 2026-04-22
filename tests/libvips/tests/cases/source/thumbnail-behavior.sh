#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/test-suite/images/sample.png"; validator_require_file "$img"; vipsthumbnail "$img" --size 32 -o "$tmpdir/thumb.png"; vipsheader "$tmpdir/thumb.png"
