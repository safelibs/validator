#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-verbose-mode
# @title: giftext -v verbose mode is accepted and produces parseable output
# @description: Runs giftext with the -v verbose flag on gifgrid.gif and confirms the tool exits zero, emits the standard descriptive blocks (Screen Size, BackGround, and Image # records) on stdout, and that the verbose run produces a line count at least as large as the non-verbose run, demonstrating verbose mode is recognized and additive rather than rejected.
# @timeout: 60
# @tags: usage, cli, giftext, verbose
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

# Baseline run without -v.
giftext "$gif" >"$tmpdir/plain.txt" 2>"$tmpdir/plain.err"
plain_lines=$(wc -l <"$tmpdir/plain.txt")
(( plain_lines > 5 )) || {
  printf 'expected non-verbose giftext to emit several lines, got %d\n' "$plain_lines" >&2
  exit 1
}

# Verbose run; some giflib builds emit progress text on stderr, so capture both.
giftext -v "$gif" >"$tmpdir/verbose.txt" 2>"$tmpdir/verbose.err"
verbose_lines=$(wc -l <"$tmpdir/verbose.txt")

# Verbose mode must not strip the descriptive output: the same headline blocks
# must still appear on stdout.
validator_assert_contains "$tmpdir/verbose.txt" 'Screen Size'
validator_assert_contains "$tmpdir/verbose.txt" 'BackGround'
grep -Eq 'Image #[0-9]+' "$tmpdir/verbose.txt"

# Verbose stdout should be at least as long as the plain run's stdout.
if (( verbose_lines < plain_lines )); then
  printf 'verbose stdout shorter than plain: verbose=%d plain=%d\n' \
    "$verbose_lines" "$plain_lines" >&2
  exit 1
fi
