#!/usr/bin/env bash
# @testcase: tiffdump-structure
# @title: tiffdump structure inspection
# @description: Runs tiffdump and checks expected TIFF structural tags are present.
# @timeout: 120
# @tags: cli, metadata

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

t="$VALIDATOR_SAMPLE_ROOT/test/images/minisblack-1c-8b.tiff"; validator_require_file "$t"; tiffdump "$t" | tee "$tmpdir/dump"; grep -Ei 'ImageWidth|ImageLength' "$tmpdir/dump"
