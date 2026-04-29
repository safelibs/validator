#!/usr/bin/env bash
# @testcase: vips-cli-load-save
# @title: vips CLI load save
# @description: Loads a sample image with vips and saves it to PNG.
# @timeout: 120
# @tags: cli, media

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/test-suite/images/sample.jpg"; validator_require_file "$img"; vips copy "$img" "$tmpdir/out.png"; vipsheader "$tmpdir/out.png" | tee "$tmpdir/h"; grep -E '[0-9]+x[0-9]+' "$tmpdir/h"
