#!/usr/bin/env bash
# @testcase: usage-python3-nacl-blake2b-raw-digest
# @title: python3-nacl blake2b raw digest
# @description: Exercises python3-nacl blake2b raw digest through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-blake2b-raw-digest"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.encoding import RawEncoder
from nacl.hash import blake2b
digest = blake2b(b'payload', encoder=RawEncoder)
assert len(digest) == 32
print(len(digest))
PYCASE
