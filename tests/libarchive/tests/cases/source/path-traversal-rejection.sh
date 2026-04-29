#!/usr/bin/env bash
# @testcase: path-traversal-rejection
# @title: Path traversal rejection
# @description: Verifies bsdtar rejects archive entries that would escape extraction.
# @timeout: 120
# @tags: cli, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/traversal.tar"
import io, sys, tarfile
with tarfile.open(sys.argv[1], 'w') as a:
    data=b'escape\n'; i=tarfile.TarInfo('../escape.txt'); i.size=len(data); a.addfile(i, io.BytesIO(data))
PY
mkdir -p "$tmpdir/out"; if bsdtar -xf "$tmpdir/traversal.tar" -C "$tmpdir/out" >"$tmpdir/log" 2>&1; then cat "$tmpdir/log"; exit 1; fi; cat "$tmpdir/log"; [[ ! -e "$tmpdir/escape.txt" ]]
