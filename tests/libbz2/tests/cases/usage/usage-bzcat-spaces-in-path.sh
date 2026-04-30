#!/usr/bin/env bash
# @testcase: usage-bzcat-spaces-in-path
# @title: bzcat handles file paths containing spaces
# @description: Compresses a file located at a path containing space characters in both directory and filename components and verifies bzcat decompresses it correctly when the quoted path is passed as a positional argument.
# @timeout: 180
# @tags: usage, bzip2, paths, spaces
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Directory and filename both contain literal spaces.
mkdir -p "$tmpdir/sub dir"
spaced_path="$tmpdir/sub dir/spaced name.txt"
printf 'bzcat reads paths with spaces fine\n' >"$spaced_path"

bzip2 -k "$spaced_path"
validator_require_file "$spaced_path.bz2"

# Quoted positional path with spaces must be honored.
bzcat "$spaced_path.bz2" >"$tmpdir/out.txt"
cmp "$spaced_path" "$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" 'bzcat reads paths with spaces fine'

# Multi-arg form with two spaced files is also expected to work.
mkdir -p "$tmpdir/another dir"
second_path="$tmpdir/another dir/second one.txt"
printf 'second spaced payload\n' >"$second_path"
bzip2 -k "$second_path"
bzcat "$spaced_path.bz2" "$second_path.bz2" >"$tmpdir/combined.txt"
validator_assert_contains "$tmpdir/combined.txt" 'bzcat reads paths with spaces fine'
validator_assert_contains "$tmpdir/combined.txt" 'second spaced payload'
