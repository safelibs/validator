#!/usr/bin/env bash
# @testcase: thumbnail-behavior
# @title: vipsthumbnail behavior
# @description: Creates a thumbnail from a sample image and inspects its header.
# @timeout: 120
# @tags: cli, thumbnail

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/test-suite/images/sample.jpg"; validator_require_file "$img"; vipsthumbnail "$img" --size 32 -o "$tmpdir/thumb.jpg"; vipsheader "$tmpdir/thumb.jpg"
