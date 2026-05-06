#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-dump-float-scientific-notation-roundtrip
# @title: PyYAML round-trips a small float through scientific-notation YAML
# @description: Loads the scientific-notation float 1.5e-10 from a YAML scalar, dumps it via yaml.safe_dump, reloads the dumped form, and asserts the value is preserved exactly (bit-equal) and remains a Python float across the round-trip.
# @timeout: 60
# @tags: usage, python3-yaml, float, roundtrip
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

original = yaml.safe_load("x: 1.5e-10\n")
assert isinstance(original['x'], float), type(original['x'])
assert original['x'] == 1.5e-10, original['x']

dumped = yaml.safe_dump(original)
back = yaml.safe_load(dumped)
assert isinstance(back['x'], float), type(back['x'])
assert back['x'] == original['x'], (back['x'], original['x'])
# bit-equal: identical float representation
import struct
assert struct.pack('>d', back['x']) == struct.pack('>d', original['x'])
PY
