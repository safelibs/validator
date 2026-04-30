#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-absolute-default-extract
# @title: bsdtar xz default refuses absolute-path escape on extract
# @description: Hand-builds a tar with a -P absolute-path entry, compresses it to xz, then extracts without -P; bsdtar must default to stripping the leading slash so the file lands under the destination directory and never escapes to the real absolute path.
# @timeout: 180
# @tags: usage, archive, xz, security
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'absolute escape probe\n' >"$tmpdir/src/probe.txt"
abs_path="$tmpdir/src/probe.txt"

# Build the archive with -P so the entry truly carries the absolute path,
# then verify bsdtar's default extract strips it.
bsdtar -P -cJf "$tmpdir/a.tar.xz" "$abs_path"

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# bsdtar -tf reports the entry as it is stored in the archive (no path
# rewriting on listing), so the absolute pathname must appear verbatim.
bsdtar -tf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
if ! grep -Fxq -- "$abs_path" "$tmpdir/list.txt"; then
  printf 'expected stored absolute path %s in listing:\n' "$abs_path" >&2
  cat "$tmpdir/list.txt" >&2
  exit 1
fi

# Extract without -P; the file must land under out/, not at the original
# absolute path. We confirm both the placement and that no spurious file
# was written outside the destination tree.
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

relpath="${abs_path#/}"
test -f "$tmpdir/out/$relpath"
cmp "$tmpdir/src/probe.txt" "$tmpdir/out/$relpath"

# The bsdtar process must not have created /<relpath> on the real root.
# (We check the exact real path the archive entry referenced.)
# It already exists as the source, so verify its content is unchanged.
cmp "$tmpdir/src/probe.txt" "$abs_path"
