#!/usr/bin/env bash
# @testcase: usage-minisign-r20-sig-blob-algo-prefix-ed
# @title: minisign signature line2 base64 blob decodes to >= 64 bytes containing the algorithm prefix
# @description: Generates a passwordless keypair and signs a payload, base64-decodes line 2 of the resulting .minisig file with python3 base64, asserts the decoded blob length is at least 64 bytes (signature algorithm tag + Ed25519 signature material), and asserts the first two bytes are the ASCII pair "Ed" (signature algorithm tag prefix Ed25519/EdDSA), confirming libsodium-backed minisign sig payload structure.
# @timeout: 60
# @tags: usage, minisign, sig, algorithm, r20
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/k.pub" -s "$tmpdir/k.sec" >/dev/null

printf 'r20 sig algo prefix payload\n' >"$tmpdir/m.txt"
minisign -S -s "$tmpdir/k.sec" -m "$tmpdir/m.txt" -W </dev/null >/dev/null

sigblob=$(sed -n '2p' "$tmpdir/m.txt.minisig")
[[ -n "$sigblob" ]] || { echo "empty sig blob" >&2; exit 1; }

python3 - "$sigblob" <<'PY'
import sys, base64
raw = base64.b64decode(sys.argv[1])
assert len(raw) >= 64, ("len", len(raw))
prefix = raw[:2]
assert prefix == b'Ed', ('prefix', prefix)
print('ok algo prefix=%r len=%d' % (prefix, len(raw)))
PY
