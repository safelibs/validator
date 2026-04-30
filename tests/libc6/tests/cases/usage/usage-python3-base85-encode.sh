#!/usr/bin/env bash
# @testcase: usage-python3-base85-encode
# @title: python3 base85 encode roundtrip
# @description: Encodes a payload with base64.b85encode and verifies b85decode reproduces the original bytes.
# @timeout: 180
# @tags: usage, python, runtime
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-base85-encode"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out" <<'PY'
import base64
import sys

out_path = sys.argv[1]
payload = b"validator-base85-roundtrip"
encoded = base64.b85encode(payload)
decoded = base64.b85decode(encoded)
with open(out_path, "w") as fh:
    fh.write("encoded=" + encoded.decode("ascii") + "\n")
    fh.write("decoded=" + decoded.decode("ascii") + "\n")
    fh.write("match=" + str(decoded == payload) + "\n")
PY

validator_assert_contains "$tmpdir/out" 'decoded=validator-base85-roundtrip'
validator_assert_contains "$tmpdir/out" 'match=True'
# encoded form must not contain the original ASCII payload verbatim
if grep -Fq 'encoded=validator-base85-roundtrip' "$tmpdir/out"; then
  printf 'b85 encoded form unexpectedly equals the plaintext\n' >&2
  exit 1
fi
