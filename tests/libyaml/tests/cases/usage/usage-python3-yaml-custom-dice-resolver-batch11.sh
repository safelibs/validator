#!/usr/bin/env bash
# @testcase: usage-python3-yaml-custom-dice-resolver-batch11
# @title: PyYAML custom dice resolver
# @description: Adds a custom implicit resolver and constructor to PyYAML.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-custom-dice-resolver-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

class DiceLoader(yaml.SafeLoader):
    pass
def construct_dice(loader, node):
    left, right = loader.construct_scalar(node).split('d')
    return (int(left), int(right))
DiceLoader.add_implicit_resolver('!dice', re.compile(r'^\d+d\d+$'), list('0123456789'))
DiceLoader.add_constructor('!dice', construct_dice)
data = yaml.load('roll: 2d6', Loader=DiceLoader)
assert data['roll'] == (2, 6)
print(data['roll'])
PYCASE
