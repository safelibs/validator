#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-verbose-flag-noninterlaced
# @title: giffix -v on a clean non-interlaced fixture matches the bare giffix output
# @description: Runs giffix with and without -v on the non-interlaced gifgrid.gif fixture, captures stdout, stderr and exit code for each, and verifies both invocations succeed (exit 0), produce byte-identical stdout, and write nothing to stderr -- confirming the -v flag is silent on a fixture that needs no repair narration.
# @timeout: 60
# @tags: usage, cli, giffix, verbose
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

# Sanity: gifgrid.gif must not be interlaced or this test is vacuous.
giftext "$gif" >"$tmpdir/info.txt"
if grep -q 'Image is Interlaced' "$tmpdir/info.txt"; then
  printf 'precondition violated: gifgrid.gif is interlaced\n' >&2
  exit 1
fi

set +e
giffix    "$gif" >"$tmpdir/plain.gif"   2>"$tmpdir/plain.err"
rc_plain=$?
giffix -v "$gif" >"$tmpdir/verbose.gif" 2>"$tmpdir/verbose.err"
rc_verbose=$?
set -e

if (( rc_plain != 0 )); then
  printf 'giffix (plain) failed with rc=%s\n' "$rc_plain" >&2
  cat "$tmpdir/plain.err" >&2
  exit 1
fi
if (( rc_verbose != 0 )); then
  printf 'giffix -v failed with rc=%s\n' "$rc_verbose" >&2
  cat "$tmpdir/verbose.err" >&2
  exit 1
fi

if [[ -s "$tmpdir/plain.err" ]]; then
  printf 'unexpected stderr from giffix (plain):\n' >&2
  cat "$tmpdir/plain.err" >&2
  exit 1
fi
if [[ -s "$tmpdir/verbose.err" ]]; then
  printf 'unexpected stderr from giffix -v on clean fixture:\n' >&2
  cat "$tmpdir/verbose.err" >&2
  exit 1
fi

if ! cmp -s "$tmpdir/plain.gif" "$tmpdir/verbose.gif"; then
  printf 'giffix and giffix -v produced different stdout bytes\n' >&2
  exit 1
fi

# And the result must still be a parseable GIF.
file "$tmpdir/verbose.gif" | grep -q 'GIF image data'
giftext "$tmpdir/verbose.gif" >"$tmpdir/after.txt"
validator_assert_contains "$tmpdir/after.txt" 'Screen Size'
