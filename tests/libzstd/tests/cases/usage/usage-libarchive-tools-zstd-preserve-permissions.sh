#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf '#!/usr/bin/env sh\nprintf zstd-permissions\n' >"$tmpdir/in/run.sh"
chmod 755 "$tmpdir/in/run.sh"

bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" run.sh
bsdtar -xf "$tmpdir/a.tar.zstd" -C "$tmpdir/out"

test -x "$tmpdir/out/run.sh"
printf 'zstd preserve permissions ok\n'
