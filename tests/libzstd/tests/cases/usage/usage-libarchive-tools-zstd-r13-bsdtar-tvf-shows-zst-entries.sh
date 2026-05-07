#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r13-bsdtar-tvf-shows-zst-entries
# @title: bsdtar -tvf on a .tar.zst lists the expected entries with mode and size columns
# @description: Builds a small directory of two files via bsdtar --zstd, runs bsdtar -tvf on the archive, and asserts the verbose listing contains both entry names and mode-prefixed rows beginning with a regular-file indicator.
# @timeout: 120
# @tags: usage, archive, zstd, bsdtar, listing
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/in"
mkdir -p "$src"
printf 'r13 tvf alpha body\n' >"$src/alpha.txt"
printf 'r13 tvf beta body\n' >"$src/beta.txt"

archive="$tmpdir/out.tar.zst"
bsdtar --zstd -cf "$archive" -C "$src" alpha.txt beta.txt

bsdtar -tvf "$archive" >"$tmpdir/listing"

# Both entries appear and rows begin with a regular-file mode prefix (- ...).
grep -q 'alpha.txt' "$tmpdir/listing"
grep -q 'beta.txt' "$tmpdir/listing"
grep -E '^-[rwx-]{9}' "$tmpdir/listing" >/dev/null || {
    printf 'expected at least one regular-file mode row in tvf listing\n' >&2
    cat "$tmpdir/listing" >&2
    exit 1
}
