#!/usr/bin/env bash
# @testcase: usage-bzip2-r19-bzdiff-rc1-content-differs
# @title: bzdiff exits 1 and prints a unified diff when archive contents differ
# @description: Compresses two text files differing in a single line, runs bzdiff capturing both rc and stdout, and asserts the exit code is 1 with stdout containing the differing tokens prefixed by "<" and ">" - locking in bzdiff exit semantics and content output for non-equal inputs.
# @timeout: 30
# @tags: usage, bzdiff, exit-code, r19
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/a.txt" <<'TXT'
shared one
left-only-line
shared two
TXT
cat >"$tmpdir/b.txt" <<'TXT'
shared one
right-only-line
shared two
TXT
bzip2 "$tmpdir/a.txt"
bzip2 "$tmpdir/b.txt"

set +e
out=$(bzdiff "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2")
rc=$?
set -e

[[ "$rc" -eq 1 ]] || {
    printf 'expected bzdiff rc=1, got %s\n' "$rc" >&2
    exit 1
}
printf '%s\n' "$out" | grep -Fq '< left-only-line' || {
    printf 'missing "< left-only-line":\n%s\n' "$out" >&2
    exit 1
}
printf '%s\n' "$out" | grep -Fq '> right-only-line' || {
    printf 'missing "> right-only-line":\n%s\n' "$out" >&2
    exit 1
}
