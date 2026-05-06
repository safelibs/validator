#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-resolver-resolve-int-implicit
# @title: PyYAML SafeLoader.resolve maps implicit numeric scalars to !!int
# @description: Constructs a SafeLoader instance and calls its resolve method on ScalarNode with values "42" and "3.14", asserting the int and float YAML 1.1 implicit tags are returned, while a generic word resolves to !!str.
# @timeout: 60
# @tags: usage, python3-yaml, resolver
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
from yaml.nodes import ScalarNode

loader = yaml.SafeLoader('')
try:
    int_tag = loader.resolve(ScalarNode, '42', (True, False))
    float_tag = loader.resolve(ScalarNode, '3.14', (True, False))
    str_tag = loader.resolve(ScalarNode, 'hello', (True, False))
finally:
    loader.dispose()

assert int_tag == 'tag:yaml.org,2002:int', int_tag
assert float_tag == 'tag:yaml.org,2002:float', float_tag
assert str_tag == 'tag:yaml.org,2002:str', str_tag
PY
