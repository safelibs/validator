#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SOURCE_ROOT/test/test-suite/images/sample.jpg"; validator_require_file "$img"; vipsthumbnail "$img" --size 32 -o "$tmpdir/thumb.jpg"; vipsheader "$tmpdir/thumb.jpg"
