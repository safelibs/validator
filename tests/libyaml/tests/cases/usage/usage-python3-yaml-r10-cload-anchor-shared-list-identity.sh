#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-cload-anchor-shared-list-identity
# @title: PyYAML CSafeLoader preserves identity of an aliased list
# @description: Loads a document where two mapping keys reference the same anchored sequence via the C-backed loader and asserts both values are the same list object via the Python `is` operator (not just equal), proving alias resolution shares storage rather than deep-copying.
# @timeout: 60
# @tags: usage, python3-yaml, libyaml, alias
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
assert hasattr(yaml, 'CSafeLoader'), 'CSafeLoader missing — libyaml not built'

text = (
    "defaults: &shared [1, 2, 3]\n"
    "override: *shared\n"
)
data = yaml.load(text, Loader=yaml.CSafeLoader)
assert data['defaults'] == [1, 2, 3], data['defaults']
assert data['override'] is data['defaults'], (id(data['defaults']), id(data['override']))

# Mutating one mutates the other (same list).
data['defaults'].append(4)
assert data['override'] == [1, 2, 3, 4], data['override']
PY
