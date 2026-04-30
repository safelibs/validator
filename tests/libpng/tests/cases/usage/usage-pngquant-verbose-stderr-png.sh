#!/usr/bin/env bash
# @testcase: usage-pngquant-verbose-stderr-png
# @title: pngquant --verbose stderr capture
# @description: Runs pngquant with --verbose on the basn2c08 PNGSuite fixture, captures stderr separately from stdout, and confirms verbose progress is on stderr while a valid PNG is still written.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-verbose-stderr-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --verbose --force --output "$tmpdir/out.png" 32 "$png" \
  >"$tmpdir/stdout.log" 2>"$tmpdir/stderr.log"

file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# pngquant's verbose progress goes to stderr; require non-empty stderr.
if [[ ! -s "$tmpdir/stderr.log" ]]; then
  printf 'expected pngquant --verbose to emit on stderr\n' >&2
  exit 1
fi

# Confirm the round-tripped image keeps the fixture's 32x32 geometry.
pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile.txt"
validator_assert_contains "$tmpdir/pamfile.txt" '32 by 32'
