#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-xzdiff-shows-content-diff
# @title: xzdiff between two xz-compressed text files reports the changed line
# @description: Compresses two text files (differing in one line) with xz and runs xzdiff, asserting that the diff output mentions the differing token, pinning xzdiff's liblzma-backed transparent decode-then-diff pipeline.
# @timeout: 60
# @tags: usage, xz, xzdiff, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/a.txt" <<'TXT'
common line
old value
common tail
TXT
cat >"$tmpdir/b.txt" <<'TXT'
common line
new value
common tail
TXT
xz -k "$tmpdir/a.txt"
xz -k "$tmpdir/b.txt"

# xzdiff returns nonzero when files differ, so capture and inspect output.
set +e
xzdiff "$tmpdir/a.txt.xz" "$tmpdir/b.txt.xz" >"$tmpdir/diff.out"
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo "expected nonzero (diff present), got 0" >&2; exit 1; }
grep -Fq 'old value' "$tmpdir/diff.out"
grep -Fq 'new value' "$tmpdir/diff.out"
