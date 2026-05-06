#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-yamlobject-subclass-roundtrip
# @title: PyYAML YAMLObject subclass roundtrips via its yaml_tag
# @description: Defines a Python class that inherits yaml.YAMLObject with a custom yaml_tag, dumps an instance via yaml.dump, asserts the emitted document carries the declared tag, and reloads it with yaml.Loader to recover an instance whose attribute matches the original.
# @timeout: 60
# @tags: usage, python3-yaml, yamlobject
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

class Box(yaml.YAMLObject):
    yaml_tag = '!Box'
    yaml_loader = yaml.Loader
    yaml_dumper = yaml.Dumper

    def __init__(self, label, count):
        self.label = label
        self.count = count

original = Box('alpha', 7)
text = yaml.dump(original)
assert '!Box' in text, text

restored = yaml.load(text, Loader=yaml.Loader)
assert isinstance(restored, Box), type(restored)
assert restored.label == 'alpha', restored.label
assert restored.count == 7, restored.count
PY
