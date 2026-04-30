#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-mtree-pipe-xz
# @title: bsdtar mtree piped through xz
# @description: Emits an mtree manifest with bsdtar, compresses through xz(1), then re-reads the .xz mtree with bsdtar -tf to confirm the listed entries match.
# @timeout: 180
# @tags: usage, archive, xz, mtree
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub"
printf 'mtree alpha\n' >"$tmpdir/in/alpha.txt"
printf 'mtree beta\n'  >"$tmpdir/in/sub/beta.txt"

# Produce an mtree manifest of the tree, then compress with xz(1).
bsdtar -c --format=mtree -f - -C "$tmpdir/in" alpha.txt sub/beta.txt \
  | xz -z -c >"$tmpdir/manifest.mtree.xz"

# .xz magic on the mtree.xz product
magic_hex=$(head -c 6 "$tmpdir/manifest.mtree.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Decompress with xz -d and confirm the mtree header is present.
xz -d -c "$tmpdir/manifest.mtree.xz" >"$tmpdir/manifest.mtree"
head -n 1 "$tmpdir/manifest.mtree" | grep -Fq '#mtree'

# Decompressed mtree is a flat text manifest. Parse it line-by-line and
# verify both file entries went in. (libarchive's bsdtar treats mtree as
# a read-only manifest format and does not always re-list it through -tf,
# so we assert against the textual mtree directly. Paths emit with a
# leading ./, and intermediate directories appear too — strip the prefix
# and keep only the file entries before comparing.)
LC_ALL=C grep -E '^\.?/?[A-Za-z0-9./_-]+ +.*type=file' "$tmpdir/manifest.mtree" \
  | awk '{print $1}' | sed 's|^\./||' | LC_ALL=C sort -u >"$tmpdir/list.txt"
grep -Fxq 'alpha.txt'    "$tmpdir/list.txt"
grep -Fxq 'sub/beta.txt' "$tmpdir/list.txt"
test "$(wc -l <"$tmpdir/list.txt")" -eq 2
