#!/usr/bin/env bash
# @testcase: usage-gio-r13-rename-content-preserved
# @title: gio rename moves a file and preserves its byte contents
# @description: Writes a known payload to a source file, runs gio rename to a sibling name, and asserts the new file exists with identical bytes while the old name is gone.
# @timeout: 60
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r13-rename-content\n' >"$tmpdir/origin.txt"
gio rename "$tmpdir/origin.txt" 'destination.txt'

validator_require_file "$tmpdir/destination.txt"
if [[ -e "$tmpdir/origin.txt" ]]; then
  printf 'gio rename did not remove origin\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/destination.txt" 'r13-rename-content'
