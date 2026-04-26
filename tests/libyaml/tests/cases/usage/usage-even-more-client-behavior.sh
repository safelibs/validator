#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

if case_id == 'usage-python3-yaml-safe-load-int-list':
    value = yaml.safe_load('- 1\n- 2\n- 3\n')
    assert value == [1, 2, 3]
    print(sum(value))
elif case_id == 'usage-python3-yaml-safe-dump-indent':
    text = yaml.safe_dump({'root': {'child': 'alpha'}}, indent=4)
    assert '    child' in text
    print(text.splitlines()[1])
elif case_id == 'usage-python3-yaml-full-load-scientific':
    value = yaml.full_load('number: 1.0e+3\n')
    parsed = value['number']
    assert str(parsed).lower() in {'1000.0', '1000', '1.0e+3'}
    print(parsed)
elif case_id == 'usage-python3-yaml-base-loader-int-string':
    value = yaml.load('count: 7\n', Loader=yaml.BaseLoader)
    assert value['count'] == '7'
    print(value['count'])
elif case_id == 'usage-python3-yaml-dump-all-explicit-end':
    text = yaml.dump_all([{'a': 1}, {'b': 2}], explicit_end=True)
    assert text.count('...') == 2
    print(text.count('...'))
elif case_id == 'usage-python3-yaml-scan-scalar-count':
    tokens = list(yaml.scan('name: alpha\nvalue: beta\n'))
    values = [token.value for token in tokens if isinstance(token, ScalarToken)]
    assert values == ['name', 'alpha', 'value', 'beta']
    print(len(values))
elif case_id == 'usage-python3-yaml-parse-mapping-start':
    events = list(yaml.parse('name: alpha\n'))
    assert any(isinstance(event, MappingStartEvent) for event in events)
    print(sum(1 for event in events if isinstance(event, MappingStartEvent)))
elif case_id == 'usage-python3-yaml-compose-mapping-node':
    node = yaml.compose('root:\n  child: alpha\n')
    assert node.value[0][0].value == 'root'
    print(node.value[0][0].value)
elif case_id == 'usage-python3-yaml-csafe-roundtrip-dict':
    loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
    dumper = getattr(yaml, 'CSafeDumper', yaml.SafeDumper)
    text = yaml.dump({'name': 'alpha', 'count': 2}, Dumper=dumper, sort_keys=True)
    value = yaml.load(text, Loader=loader)
    assert value == {'count': 2, 'name': 'alpha'}
    print(value['name'], value['count'])
elif case_id == 'usage-python3-yaml-safe-load-nested-sequence':
    value = yaml.safe_load('root:\n  - [1, 2]\n  - [3, 4]\n')
    assert value == {'root': [[1, 2], [3, 4]]}
    print(value['root'][1][1])
else:
    raise SystemExit(f'unknown libyaml even-more usage case: {case_id}')
PY
