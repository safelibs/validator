#!/usr/bin/env bash
# @testcase: metadata-header-checks
# @title: vips metadata header checks
# @description: Inspects detailed image metadata using vipsheader on a PNG fixture.
# @timeout: 120
# @tags: cli, metadata

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/test-suite/images/sample.png"; validator_require_file "$img"; vipsheader -a "$img" | tee "$tmpdir/h"; grep -E 'width|height|bands' "$tmpdir/h"
