#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-bzip2recover-truncated-fragment
# @title: bzip2recover writes rec00001 fragment for a truncated archive
# @description: Compresses a multi-line payload, truncates the resulting .bz2 to half its size, runs bzip2recover, and asserts a rec*0001*.bz2 fragment file is produced in the working directory — locking in bzip2recover's standard fragment naming for partially-readable archives.
# @timeout: 60
# @tags: usage, bzip2recover, truncated
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Generate substantial input so the .bz2 contains at least one full block.
python3 -c "import sys; [sys.stdout.write(f'line {i} alpha bravo charlie\n') for i in range(2000)]" \
    >"$tmpdir/payload.txt"
bzip2 -c "$tmpdir/payload.txt" >"$tmpdir/payload.bz2"

orig=$(stat -c %s "$tmpdir/payload.bz2")
half=$((orig / 2))
[[ "$half" -gt 64 ]]
dd if="$tmpdir/payload.bz2" of="$tmpdir/truncated.bz2" bs=1 count="$half" status=none

cd "$tmpdir"
# bzip2recover may exit non-zero on truncated input; tolerate that and check
# for the fragment file shape afterwards.
bzip2recover "$tmpdir/truncated.bz2" >"$tmpdir/recover.out" 2>"$tmpdir/recover.err" || true

# Standard bzip2recover naming: rec00001truncated.bz2 (or similar with leading
# zeros). Match the 0001 fragment using a glob.
shopt -s nullglob
matches=("$tmpdir"/rec*0001*.bz2)
shopt -u nullglob
[[ ${#matches[@]} -ge 1 ]] || {
    printf 'no rec00001 fragment produced\n' >&2
    ls -la "$tmpdir" >&2
    cat "$tmpdir/recover.err" >&2
    exit 1
}
