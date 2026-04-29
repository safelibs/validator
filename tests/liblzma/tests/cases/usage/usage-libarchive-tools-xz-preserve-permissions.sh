#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-preserve-permissions
# @title: libarchive-tools xz preserve permissions
# @description: Runs bsdtar xz archive extraction and verifies executable permissions survive.
# @timeout: 180
# @tags: usage, archive, compression, metadata
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf '#!/usr/bin/env sh\nprintf xz-permissions\n' >"$tmpdir/in/run.sh"
chmod 755 "$tmpdir/in/run.sh"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" run.sh
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"

test -x "$tmpdir/out/run.sh"
printf 'xz preserve permissions ok\n'
