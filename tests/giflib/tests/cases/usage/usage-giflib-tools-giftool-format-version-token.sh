#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-format-version-token
# @title: giftool -f reports GIF87a version and screen size
# @description: Asks giftool -f to print the version cookie and screen-size pair for a GIF87a fixture and confirms the emitted tokens match the expected values, exercising the %v and %s format directives together.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

# Confirm the source fixture really is GIF87a so the assertion is meaningful.
file "$gif" | grep -q 'version 87a'

# Read the screen dimensions giftext sees, so the %s assertion is grounded
# in the actual fixture and not hardcoded. giftext prints
#   "Screen Size - Width = N, Height = M."
giftext "$gif" >"$tmpdir/text.txt"
expected_size=$(sed -n 's/.*Screen Size - Width = \([0-9]*\), Height = \([0-9]*\)\..*/\1,\2/p' "$tmpdir/text.txt" | head -n1)
if [[ -z "$expected_size" ]]; then
  printf 'could not parse screen size from giftext output\n' >&2
  cat "$tmpdir/text.txt" >&2
  exit 1
fi

giftool -f 'v=%v s=%s\n' <"$gif" >"$tmpdir/info.txt"
first_line=$(head -n 1 "$tmpdir/info.txt")

if [[ "$first_line" != "v=GIF87a s=$expected_size" ]]; then
  printf 'expected first line of giftool -f output to be "v=GIF87a s=%s", got: %s\n' \
    "$expected_size" "$first_line" >&2
  exit 1
fi
