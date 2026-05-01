#!/usr/bin/env bash
# @testcase: usage-exif-cli-usage-brief-banner
# @title: exif --usage prints brief getopt synopsis
# @description: Runs exif --usage and confirms the brief synopsis bundles the short-option cluster Usage: exif [-?vil|sercmxd] and lists the long-option synopsis tokens for --width, --xml-output, --debug, and the trailing OPTION...] file marker, distinct from the verbose --help screen.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-usage-brief-banner"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

exif --usage >"$tmpdir/out" 2>&1

validator_assert_contains "$tmpdir/out" 'Usage: exif [-?vil|sercmxd]'
validator_assert_contains "$tmpdir/out" '[-?|--help]'
validator_assert_contains "$tmpdir/out" '[--usage]'
validator_assert_contains "$tmpdir/out" '[-v|--version]'
validator_assert_contains "$tmpdir/out" '[-l|--list-tags]'
validator_assert_contains "$tmpdir/out" '[-o|--output=FILE]'
validator_assert_contains "$tmpdir/out" '[--set-value=STRING]'
validator_assert_contains "$tmpdir/out" '[-c|--create-exif]'
validator_assert_contains "$tmpdir/out" '[-w|--width=WIDTH]'
validator_assert_contains "$tmpdir/out" '[-x|--xml-output]'
validator_assert_contains "$tmpdir/out" '[-d|--debug]'
validator_assert_contains "$tmpdir/out" '[OPTION...] file'

# --usage must NOT contain the verbose --help banner header
if grep -Fq -- 'Help options:' "$tmpdir/out"; then
  printf '--usage output unexpectedly contained verbose Help options block\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
