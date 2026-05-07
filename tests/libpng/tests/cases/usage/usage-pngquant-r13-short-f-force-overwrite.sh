#!/usr/bin/env bash
# @testcase: usage-pngquant-r13-short-f-force-overwrite
# @title: pngquant -f short flag overwrites an existing target file
# @description: Pre-creates a sentinel file at the chosen output path with a known SHA-256, then runs pngquant -f -o <path> against a synthetic input and verifies the target file's hash changed (proving -f acted as a synonym of --force) and the file is still a valid PNG.
# @timeout: 120
# @tags: usage, image, png, cli, short-flag
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 24, 24
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 10) & 0xff, (y * 10) & 0xff, 64))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

# Pre-create a sentinel file at the output path that pngquant must overwrite.
printf 'sentinel-X9Y3\n' >"$tmpdir/out.png"
sentinel_sha=$(sha256sum "$tmpdir/out.png" | awk '{print $1}')

pngquant -f -o "$tmpdir/out.png" 16 "$tmpdir/in.png"

# After --force/-f, the target SHA must have changed.
new_sha=$(sha256sum "$tmpdir/out.png" | awk '{print $1}')
[[ "$new_sha" != "$sentinel_sha" ]] || {
  printf 'pngquant -f did not overwrite sentinel file (sha unchanged)\n' >&2
  exit 1
}

# And the new file must be a valid PNG.
python3 - "$tmpdir/out.png" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n', data[:8]
PY
