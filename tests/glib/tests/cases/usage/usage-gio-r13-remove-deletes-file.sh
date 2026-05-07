#!/usr/bin/env bash
# @testcase: usage-gio-r13-remove-deletes-file
# @title: gio remove deletes a regular file from disk
# @description: Creates a small file, runs gio remove against it, and asserts the path no longer exists on disk while the parent directory is preserved.
# @timeout: 60
# @tags: usage, gio, filesystem
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r13 remove payload\n' >"$tmpdir/victim.txt"
validator_require_file "$tmpdir/victim.txt"

gio remove "$tmpdir/victim.txt"

if [[ -e "$tmpdir/victim.txt" ]]; then
  printf 'gio remove left file in place\n' >&2
  exit 1
fi
validator_require_dir "$tmpdir"
