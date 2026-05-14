#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-xz-keep-preserves-source
# @title: xz --keep retains the source file alongside the .xz output
# @description: Runs xz --keep on a payload and asserts both the original file and the corresponding .xz output exist after the run, pinning the documented no-delete-source behavior.
# @timeout: 60
# @tags: usage, xz, keep, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r18 keep payload\n' >"$tmpdir/data.txt"
xz --keep "$tmpdir/data.txt"

test -f "$tmpdir/data.txt"     || { printf 'source removed despite --keep\n' >&2; exit 1; }
test -f "$tmpdir/data.txt.xz"  || { printf 'expected .xz output is missing\n' >&2; exit 1; }
