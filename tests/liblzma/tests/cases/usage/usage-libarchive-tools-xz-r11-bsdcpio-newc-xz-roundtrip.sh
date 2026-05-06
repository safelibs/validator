#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-bsdcpio-newc-xz-roundtrip
# @title: bsdcpio --format=newc with xz compression round-trips a regular file
# @description: Pipes a single regular file through bsdcpio -o --format=newc | xz -c, then decodes the .xz stream and pipes it back through bsdcpio -i --no-absolute-filenames, verifying the extracted byte-equal payload and that bsdcpio -t lists the original entry name.
# @timeout: 60
# @tags: usage, xz, bsdcpio
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'cpio newc xz alpha beta gamma\n' >"$tmpdir/in/payload.txt"
src_sha=$(sha256sum "$tmpdir/in/payload.txt" | awk '{print $1}')

(cd "$tmpdir/in" && printf 'payload.txt\n' | bsdcpio --quiet -o --format=newc) \
  | xz -c >"$tmpdir/payload.cpio.xz"

magic_hex=$(head -c 6 "$tmpdir/payload.cpio.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz -dc "$tmpdir/payload.cpio.xz" \
  | bsdcpio --quiet -t >"$tmpdir/listing.txt"
listing=$(cat "$tmpdir/listing.txt")
test "$listing" = "payload.txt"

(cd "$tmpdir/out" && xz -dc "$tmpdir/payload.cpio.xz" \
   | bsdcpio --quiet -i --no-absolute-filenames)

out_sha=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
