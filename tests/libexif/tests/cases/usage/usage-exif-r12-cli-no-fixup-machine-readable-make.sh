#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-no-fixup-machine-readable-make
# @title: exif --no-fixup --machine-readable returns Make=Canon unchanged from the on-disk bytes
# @description: Reads Make in machine-readable mode with --no-fixup, which suppresses libexif's tag normalisation pass, and verifies the output is exactly "Canon", asserting the no-fixup path still surfaces present tags identically for tags that need no fixup.
# @timeout: 60
# @tags: usage, no-fixup, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --no-fixup --machine-readable --tag=Make "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "Canon" ]]; then
  printf 'expected Canon, got: %s\n' "$value" >&2
  exit 1
fi
