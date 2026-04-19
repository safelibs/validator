#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

if g-ir-inspect Vips --print-shlibs >"$tmpdir/gir" 2>&1; then cat "$tmpdir/gir"; elif g-ir-inspect Vips-8.0 --print-shlibs >"$tmpdir/gir" 2>&1; then cat "$tmpdir/gir"; else cat "$tmpdir/gir"; exit 1; fi; grep -i vips "$tmpdir/gir"
