#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-custom-class-representer-roundtrip
# @title: PyYAML SafeDumper add_representer for a custom class emits a flow mapping that safe_load reads back
# @description: Registers a SafeDumper representer that serializes a small dataclass-like object as a YAML mapping of its fields, dumps an instance through yaml.safe_dump, and asserts the result loads back via yaml.safe_load to the same field dict.
# @timeout: 60
# @tags: usage, python3-yaml, representer, custom
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

def point_repr(dumper, data):
    return dumper.represent_mapping(
        'tag:yaml.org,2002:map', {'x': data.x, 'y': data.y}
    )

yaml.SafeDumper.add_representer(Point, point_repr)

text = yaml.safe_dump({'pt': Point(3, 4)})
back = yaml.safe_load(text)
assert back == {'pt': {'x': 3, 'y': 4}}, back
PY
