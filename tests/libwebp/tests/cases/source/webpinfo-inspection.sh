#!/usr/bin/env bash
# @testcase: webpinfo-inspection
# @title: webpinfo inspection
# @description: Inspects a checked-in WebP example through the webpinfo tool.
# @timeout: 120
# @tags: cli, metadata

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

w="$VALIDATOR_SAMPLE_ROOT/examples/test.webp"; validator_require_file "$w"; webpinfo "$w" | tee "$tmpdir/i"; grep -Ei 'RIFF|Canvas|VP8' "$tmpdir/i"
