#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/dir" "$tmpdir/tar" "$tmpdir/zip"; printf 'alpha\n' >"$tmpdir/in/dir/a.txt"; printf 'beta\n' >"$tmpdir/in/b.txt"; bsdtar -cf "$tmpdir/a.tar" -C "$tmpdir/in" .; bsdtar --format zip -cf "$tmpdir/a.zip" -C "$tmpdir/in" .; bsdtar -tf "$tmpdir/a.tar" | LC_ALL=C sort; bsdtar -tf "$tmpdir/a.zip" | LC_ALL=C sort; bsdtar -xf "$tmpdir/a.tar" -C "$tmpdir/tar"; bsdtar -xf "$tmpdir/a.zip" -C "$tmpdir/zip"; cmp "$tmpdir/in/dir/a.txt" "$tmpdir/tar/dir/a.txt"; cmp "$tmpdir/in/b.txt" "$tmpdir/zip/b.txt"
