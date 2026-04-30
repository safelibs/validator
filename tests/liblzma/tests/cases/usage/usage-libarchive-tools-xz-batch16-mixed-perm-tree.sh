#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-mixed-perm-tree
# @title: bsdtar xz mixed permission tree
# @description: Round-trips a directory tree with mixed 755/644/600 permissions through an xz-compressed tar archive and verifies modes are preserved.
# @timeout: 180
# @tags: usage, archive, xz, perms
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/sub"
printf '#!/bin/sh\necho exec\n' >"$tmpdir/src/exec.sh"
chmod 755 "$tmpdir/src/exec.sh"
printf 'public payload\n' >"$tmpdir/src/sub/public.txt"
chmod 644 "$tmpdir/src/sub/public.txt"
printf 'secret payload\n' >"$tmpdir/src/sub/secret.txt"
chmod 600 "$tmpdir/src/sub/secret.txt"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" .

mkdir "$tmpdir/out"
bsdtar -xpf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

test "$(stat -c %a "$tmpdir/out/exec.sh")" = 755
test "$(stat -c %a "$tmpdir/out/sub/public.txt")" = 644
test "$(stat -c %a "$tmpdir/out/sub/secret.txt")" = 600

cmp "$tmpdir/src/exec.sh" "$tmpdir/out/exec.sh"
cmp "$tmpdir/src/sub/public.txt" "$tmpdir/out/sub/public.txt"
cmp "$tmpdir/src/sub/secret.txt" "$tmpdir/out/sub/secret.txt"
