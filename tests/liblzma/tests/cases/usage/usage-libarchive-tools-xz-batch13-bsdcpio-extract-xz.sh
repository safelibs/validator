#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-bsdcpio-extract-xz
# @title: bsdcpio -i extracts xz cpio
# @description: Builds a newc cpio compressed with xz(1) and confirms bsdcpio -idum decodes it via liblzma producing byte-identical files.
# @timeout: 180
# @tags: usage, archive, xz, cpio
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/dir" "$tmpdir/out"
printf 'cpio extract alpha\n' >"$tmpdir/in/alpha.txt"
printf 'cpio extract beta\n' >"$tmpdir/in/dir/beta.txt"
sha_alpha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
sha_beta=$(sha256sum "$tmpdir/in/dir/beta.txt" | awk '{print $1}')

# Build a plain newc cpio, then compress with xz(1).
(
  cd "$tmpdir/in"
  find . -type f -print0 | bsdcpio -o0 --format newc >"$tmpdir/a.cpio"
)
xz -z -c "$tmpdir/a.cpio" >"$tmpdir/a.cpio.xz"

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.cpio.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# bsdcpio reads xz transparently via libarchive (-> liblzma).
(
  cd "$tmpdir/out"
  bsdcpio -idum <"$tmpdir/a.cpio.xz"
)

test "$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')" = "$sha_alpha"
test "$(sha256sum "$tmpdir/out/dir/beta.txt" | awk '{print $1}')" = "$sha_beta"
