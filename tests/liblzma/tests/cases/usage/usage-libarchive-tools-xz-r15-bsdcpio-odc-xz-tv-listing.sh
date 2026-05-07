#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-bsdcpio-odc-xz-tv-listing
# @title: bsdcpio odc cpio piped through xz then listed back with -tv shows mode columns
# @description: Pipes a file list into "bsdcpio -o -H odc | xz -z -c" producing an .odc.cpio.xz archive, asserts the .xz outer magic, decompresses with xz -dc and pipes through "bsdcpio -i -tv" (verbose listing) and asserts each member name is present along with a leading '-' file-type character on each verbose line — distinct from the existing batch18 odc-xz case which only checks plain "-i -t" listing.
# @timeout: 120
# @tags: usage, bsdcpio, odc, xz, listing, verbose
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/work"
printf 'r15 odc-xz-tv alpha\n' >"$tmpdir/src/alpha.txt"
printf 'r15 odc-xz-tv beta longer\n'  >"$tmpdir/src/beta.txt"

cd "$tmpdir/src"
printf 'alpha.txt\nbeta.txt\n' | bsdcpio -o -H odc 2>/dev/null | xz -z -c >"$tmpdir/work/a.cpio.xz"

magic_hex=$(head -c 6 "$tmpdir/work/a.cpio.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz -dc "$tmpdir/work/a.cpio.xz" | bsdcpio -i -tv 2>/dev/null >"$tmpdir/work/list.txt"

# Each verbose listing line begins with a '-' (regular file type char).
[[ "$(wc -l <"$tmpdir/work/list.txt")" == "2" ]]
[[ "$(grep -cE '^-' "$tmpdir/work/list.txt")" == "2" ]]

# Both member names appear somewhere in the verbose output.
grep -Fq 'alpha.txt' "$tmpdir/work/list.txt"
grep -Fq 'beta.txt'  "$tmpdir/work/list.txt"
