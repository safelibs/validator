#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-xp-preserves-executable-mode
# @title: bsdtar extracts a tar.zst preserving the executable bit on a 0755-mode member
# @description: Creates a script file with permissions 0755, packs it into a tar.zst archive, extracts to a fresh directory, and asserts the extracted file retains the executable bit for the owner — pinning libarchive's mode preservation across the zstd-compressed tar path.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, mode, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
printf '#!/bin/sh\necho hi\n' >"$src/run.sh"
chmod 0755 "$src/run.sh"
src_mode=$(stat -c '%a' "$src/run.sh")
[[ "$src_mode" == "755" ]] || { printf 'expected source mode 755, got %s\n' "$src_mode" >&2; exit 1; }

(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" run.sh)

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar -xpf "$tmpdir/archive.tar.zst")

out_mode=$(stat -c '%a' "$dest/run.sh")
[[ "$out_mode" == "755" ]] || { printf 'expected extracted mode 755, got %s\n' "$out_mode" >&2; exit 1; }
[[ -x "$dest/run.sh" ]] || { echo "expected extracted file to be executable" >&2; exit 1; }
