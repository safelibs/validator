#!/usr/bin/env bash
# @testcase: usage-gio-r20-cat-binary-256-bytes-byte-count
# @title: gio cat on a 256-byte binary file emits exactly 256 bytes on stdout
# @description: Writes 256 sequential bytes (0..255) to a binary file in tmpdir, runs gio cat against it, and asserts the captured stdout is exactly 256 bytes via wc -c, exercising the binary-safe byte-count fidelity of gio cat distinct from prior payload-equality or newline-count tests.
# @timeout: 60
# @tags: usage, gio, cat, binary, r20
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys; sys.stdout.buffer.write(bytes(range(256)))' >"$tmpdir/bin.dat"
size=$(stat -c '%s' "$tmpdir/bin.dat")
[[ "$size" == "256" ]] || { printf 'fixture size mismatch: %s\n' "$size" >&2; exit 1; }

gio cat "$tmpdir/bin.dat" >"$tmpdir/out.bin"
got=$(stat -c '%s' "$tmpdir/out.bin")
[[ "$got" == "256" ]] || { printf 'cat output size mismatch: %s\n' "$got" >&2; exit 1; }

cmp "$tmpdir/bin.dat" "$tmpdir/out.bin"
