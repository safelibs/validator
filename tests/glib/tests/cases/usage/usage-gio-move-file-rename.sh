#!/usr/bin/env bash
# @testcase: usage-gio-move-file-rename
# @title: gio moves file
# @description: Moves a local file with gio move and verifies the destination content and source removal.
# @timeout: 180
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-move-file-rename"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'gio move payload\n' >"$tmpdir/input.txt"
gio move "$tmpdir/input.txt" "$tmpdir/output.txt"
validator_assert_contains "$tmpdir/output.txt" 'gio move payload'
if [[ -e "$tmpdir/input.txt" ]]; then
  printf 'gio move unexpectedly left the source file behind\n' >&2
  exit 1
fi
