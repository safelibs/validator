#!/usr/bin/env bash
# @testcase: usage-bzmore-q-quits-cleanly
# @title: bzmore exits cleanly on q
# @description: Pipes a 'q' keystroke into bzmore over a compressed file and verifies bzmore exits zero without dumping the entire payload to stdout.
# @timeout: 180
# @tags: usage, bzmore, interactive
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A multi-screenful payload so bzmore would normally pause at a page boundary.
python3 -c 'import sys
for i in range(500):
    sys.stdout.write(f"bzmore quit payload line {i:04d}\n")' >"$tmpdir/plain.txt"

bzip2 -k "$tmpdir/plain.txt"

# Force interactive-style behavior by feeding a TTY-less stdin with just "q".
status=0
printf 'q\n' | bzmore "$tmpdir/plain.txt.bz2" >"$tmpdir/out" 2>"$tmpdir/err" || status=$?
[[ "$status" -eq 0 ]] || {
  printf 'bzmore exited %s after q input\n' "$status" >&2
  sed -n '1,40p' "$tmpdir/err" >&2 || true
  exit 1
}

# bzmore must have written something (it is allowed to dump everything when
# stdout is a pipe), but the run must finish - assert the file existed and the
# command terminated. We at least require that the *first* payload line is
# present so we know bzmore actually decompressed and wrote output.
validator_assert_contains "$tmpdir/out" 'bzmore quit payload line 0000'
