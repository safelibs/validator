#!/usr/bin/env bash
# @testcase: usage-findutils-r21-printf-y-type-letter
# @title: find -printf "%y" emits the type letter for regular files and directories
# @description: Builds a directory containing one regular file, then runs find -printf "%y\n" and asserts the captured output contains both "d" (for the directory) and "f" (for the regular file) - locking in the -printf %y format-letter rendering distinct from prior -printf permissions/size tests.
# @timeout: 30
# @tags: usage, findutils, printf, type-letter, r21
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/work"
printf 'x\n' >"$tmpdir/work/file.txt"

find "$tmpdir/work" -printf '%y\n' | sort -u >"$tmpdir/out.txt"

validator_assert_contains "$tmpdir/out.txt" 'd'
validator_assert_contains "$tmpdir/out.txt" 'f'
