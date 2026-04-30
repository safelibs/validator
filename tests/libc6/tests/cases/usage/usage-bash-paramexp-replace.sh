#!/usr/bin/env bash
# @testcase: usage-bash-paramexp-replace
# @title: bash parameter expansion global replace
# @description: Uses ${var//pattern/repl} to globally replace a substring in a bash variable and verifies the rewritten value byte-for-byte.
# @timeout: 180
# @tags: usage, bash, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-paramexp-replace"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

input='foo-bar-foo-baz-foo'
all_replaced=${input//foo/QUX}
prefix_only=${input/#foo/QUX}
suffix_only=${input/%foo/QUX}

printf '%s\n' "$all_replaced" >"$tmpdir/all.out"
printf '%s\n' "$prefix_only" >"$tmpdir/prefix.out"
printf '%s\n' "$suffix_only" >"$tmpdir/suffix.out"

expected_all='QUX-bar-QUX-baz-QUX'
expected_prefix='QUX-bar-foo-baz-foo'
expected_suffix='foo-bar-foo-baz-QUX'

actual_all=$(cat "$tmpdir/all.out")
actual_prefix=$(cat "$tmpdir/prefix.out")
actual_suffix=$(cat "$tmpdir/suffix.out")

if [[ "$actual_all" != "$expected_all" ]]; then
  printf 'global replace mismatch: %s\n' "$actual_all" >&2
  exit 1
fi
if [[ "$actual_prefix" != "$expected_prefix" ]]; then
  printf 'prefix-anchored replace mismatch: %s\n' "$actual_prefix" >&2
  exit 1
fi
if [[ "$actual_suffix" != "$expected_suffix" ]]; then
  printf 'suffix-anchored replace mismatch: %s\n' "$actual_suffix" >&2
  exit 1
fi
