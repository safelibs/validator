#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-bsdcpio-newc-xz
# @title: bsdcpio newc format piped through xz
# @description: Pipes a file list into bsdcpio -o -H newc and through xz -z to produce a newc.cpio.xz, then validates xz magic, decompresses with xz -d, and re-reads via bsdcpio -i -t to confirm member names survive round-trip.
# @timeout: 180
# @tags: usage, archive, xz, cpio, newc
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/work"
printf 'newc cpio alpha body\n' >"$tmpdir/src/alpha.txt"
printf 'newc cpio beta body\n'  >"$tmpdir/src/beta.txt"

cd "$tmpdir/src"
printf 'alpha.txt\nbeta.txt\n' | bsdcpio -o -H newc 2>/dev/null | xz -z -c >"$tmpdir/work/a.cpio.xz"

magic_hex=$(head -c 6 "$tmpdir/work/a.cpio.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz -d -c "$tmpdir/work/a.cpio.xz" >"$tmpdir/work/a.cpio"

# newc magic is "070701" in ASCII at byte 0.
header=$(head -c 6 "$tmpdir/work/a.cpio")
test "$header" = "070701"

bsdcpio -i -t <"$tmpdir/work/a.cpio" >"$tmpdir/work/list" 2>/dev/null
validator_assert_contains "$tmpdir/work/list" 'alpha.txt'
validator_assert_contains "$tmpdir/work/list" 'beta.txt'
