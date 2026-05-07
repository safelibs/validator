#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-cli-progress-stderr-output
# @title: zstd --progress writes a progress line to stderr while -q --no-progress stays silent
# @description: Compresses a payload twice: once with zstd --progress (stderr output expected) and once with -q --no-progress (stderr expected to be empty). Asserts the --progress run prints something to stderr and the --no-progress run produces no stderr output, while both compressions still produce identical decoded bodies.
# @timeout: 60
# @tags: usage, archive, zstd, cli, progress
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"r15 progress payload row\n" * 8000)' >"$src"
src_sum=$(sha256sum "$src" | awk '{print $1}')

# Run 1: --progress -> stderr should be non-empty.
zstd --progress -o "$tmpdir/p1.zst" "$src" 2>"$tmpdir/p1.err" >/dev/null
[[ -s "$tmpdir/p1.err" ]] || {
    printf 'expected non-empty stderr from --progress\n' >&2
    exit 1
}

# Run 2: -q --no-progress -> stderr must be empty.
zstd -q --no-progress -o "$tmpdir/p2.zst" "$src" 2>"$tmpdir/p2.err" >/dev/null
if [[ -s "$tmpdir/p2.err" ]]; then
    printf 'unexpected stderr under -q --no-progress:\n' >&2
    cat "$tmpdir/p2.err" >&2
    exit 1
fi

# Both archives must decode to the identical source.
zstd -dq -c "$tmpdir/p1.zst" >"$tmpdir/d1.bin"
zstd -dq -c "$tmpdir/p2.zst" >"$tmpdir/d2.bin"
test "$src_sum" = "$(sha256sum "$tmpdir/d1.bin" | awk '{print $1}')"
test "$src_sum" = "$(sha256sum "$tmpdir/d2.bin" | awk '{print $1}')"
