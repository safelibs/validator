#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"; printf 'cpio payload\n' >"$tmpdir/in/sub/payload.txt"; (cd "$tmpdir/in" && find . -print | sort | bsdcpio -o -H newc >"$tmpdir/a.cpio"); (cd "$tmpdir/out" && bsdcpio -id <"$tmpdir/a.cpio"); cmp "$tmpdir/in/sub/payload.txt" "$tmpdir/out/sub/payload.txt"; bsdcpio -it <"$tmpdir/a.cpio"
