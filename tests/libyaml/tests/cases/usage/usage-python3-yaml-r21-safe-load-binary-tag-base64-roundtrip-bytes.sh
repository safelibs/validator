#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-load-binary-tag-base64-roundtrip-bytes
# @title: PyYAML safe_load decodes a !!binary scalar and PyYAML safe_dump roundtrips back to bytes equal to the original
# @description: Dumps a known bytes payload via yaml.safe_dump (producing a !!binary base64 scalar), then reloads via yaml.safe_load and asserts the recovered value equals the original bytes — pinning libyaml's binary tag base64 encode/decode roundtrip through python3-yaml.
# @timeout: 60
# @tags: usage, python3-yaml, binary, base64, roundtrip, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

payload = bytes(range(256))
dumped = yaml.safe_dump(payload)
# Sanity: an explicit !!binary tag must appear in the dumped form.
assert '!!binary' in dumped, dumped
roundtripped = yaml.safe_load(dumped)
assert isinstance(roundtripped, bytes), type(roundtripped)
assert roundtripped == payload, (len(roundtripped), len(payload))
PY
