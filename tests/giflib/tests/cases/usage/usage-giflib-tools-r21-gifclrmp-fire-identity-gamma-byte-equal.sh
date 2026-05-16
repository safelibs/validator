#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-gifclrmp-fire-identity-gamma-byte-equal
# @title: gifclrmp -g 1.0 on fire.gif applied twice converges to a fixed-point GIF
# @description: Applies gifclrmp -g 1.0 (identity gamma) to fire.gif once, then applies it a second time to the result, and asserts the second and third outputs are byte-for-byte identical (the identity-gamma transform is idempotent after the first canonicalisation pass), exercising the gamma fixed-point property distinct from the existing 256-palette-row identity-gamma test.
# @timeout: 60
# @tags: usage, cli, gifclrmp, gamma, idempotent, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifclrmp -g 1.0 "$gif" >"$tmpdir/g1.gif"
gifclrmp -g 1.0 "$tmpdir/g1.gif" >"$tmpdir/g2.gif"
gifclrmp -g 1.0 "$tmpdir/g2.gif" >"$tmpdir/g3.gif"

cmp "$tmpdir/g2.gif" "$tmpdir/g3.gif"
file "$tmpdir/g3.gif" | grep -q 'GIF image data'
