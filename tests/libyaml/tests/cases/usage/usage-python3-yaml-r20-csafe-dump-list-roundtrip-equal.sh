#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-csafe-dump-list-roundtrip-equal
# @title: PyYAML yaml.dump with CSafeDumper then yaml.safe_load roundtrips a list of mixed scalars
# @description: Dumps the Python list [1, 'two', 3.5, True, None] via yaml.dump with Dumper=yaml.CSafeDumper, then loads it back with yaml.safe_load and asserts the recovered value is equal to the original list element-by-element and type-by-type — pinning the C-backed emitter/parser path for mixed-type sequences.
# @timeout: 60
# @tags: usage, python3-yaml, csafe-dumper, roundtrip, mixed-types, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = [1, 'two', 3.5, True, None]
out = yaml.dump(data, Dumper=yaml.CSafeDumper)
back = yaml.safe_load(out)
assert back == data, (back, data)
assert all(type(a) is type(b) for a, b in zip(back, data)), [type(x) for x in back]
PY
