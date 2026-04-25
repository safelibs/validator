#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

if case_id == "usage-python3-yaml-merge-keys":
    data = yaml.safe_load('base: &base {name: alpha, count: 2}\nitem: {<<: *base, count: 3}\n')
    assert data['item']['name'] == 'alpha' and data['item']['count'] == 3
    print(data['item']['name'], data['item']['count'])
elif case_id == "usage-python3-yaml-block-scalar":
    data = yaml.safe_load('text: |\n  alpha\n  beta\n')
    assert data['text'] == 'alpha\nbeta\n'
    print(data['text'].splitlines()[1])
elif case_id == "usage-python3-yaml-flow-style":
    dumped = yaml.safe_dump({'alpha': 1, 'beta': 2}, default_flow_style=True)
    assert '{' in dumped and 'alpha' in dumped
    print(dumped.strip())
elif case_id == "usage-python3-yaml-explicit-start":
    dumped = yaml.safe_dump({'alpha': 1}, explicit_start=True)
    assert dumped.startswith('---')
    print(dumped.splitlines()[0])
elif case_id == "usage-python3-yaml-csafe-multidoc":
    loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
    docs = list(yaml.load_all('---\na: 1\n---\nb: 2\n', Loader=loader))
    assert len(docs) == 2
    print('docs', len(docs))
elif case_id == "usage-python3-yaml-csafe-binary-dump":
    dumper = getattr(yaml, 'CSafeDumper', yaml.SafeDumper)
    loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
    dumped = yaml.dump({'payload': b'abc'}, Dumper=dumper)
    data = yaml.load(dumped, Loader=loader)
    assert data['payload'] == b'abc'
    print('binary', len(data['payload']))
elif case_id == "usage-python3-yaml-full-loader-date":
    data = yaml.load('day: 2024-01-02\n', Loader=yaml.FullLoader)
    assert data['day'] == datetime.date(2024, 1, 2)
    print(data['day'].isoformat())
elif case_id == "usage-python3-yaml-sorted-dump":
    dumped = yaml.safe_dump({'b': 2, 'a': 1}, sort_keys=True)
    assert dumped.splitlines()[0] == 'a: 1'
    print(dumped.splitlines()[0])
elif case_id == "usage-python3-yaml-alias-identity":
    data = yaml.safe_load('left: &node [1, 2]\nright: *node\n')
    assert data['left'] == data['right'] == [1, 2]
    print(data['right'])
elif case_id == "usage-python3-yaml-scan-tokens":
    tokens = list(yaml.scan('name: alpha\n'))
    assert any(isinstance(token, ScalarToken) and token.value == 'alpha' for token in tokens)
    print('tokens', len(tokens))
elif case_id == "usage-python3-yaml-safe-load-all":
    docs = list(yaml.safe_load_all('---\na: 1\n---\nb: 2\n'))
    assert docs == [{'a': 1}, {'b': 2}]
    print('docs', len(docs))
elif case_id == "usage-python3-yaml-folded-scalar":
    data = yaml.safe_load('text: >\n  alpha\n  beta\n')
    assert data['text'] == 'alpha beta\n'
    print(data['text'].strip())
elif case_id == "usage-python3-yaml-safe-dump-unicode":
    dumped = yaml.safe_dump({'name': 'caf\u00e9'}, allow_unicode=True)
    assert 'caf\u00e9' in dumped
    print(dumped.strip())
elif case_id == "usage-python3-yaml-full-loader-bool":
    data = yaml.load('flag: true\n', Loader=yaml.FullLoader)
    assert data['flag'] is True
    print(data['flag'])
elif case_id == "usage-python3-yaml-parse-events":
    events = list(yaml.parse('name: alpha\n'))
    assert any(isinstance(event, ScalarEvent) and event.value == 'alpha' for event in events)
    print('events', len(events))
elif case_id == "usage-python3-yaml-compose-node":
    node = yaml.compose('root:\n  child: 1\n')
    assert node.value[0][0].value == 'root'
    print(node.tag)
elif case_id == "usage-python3-yaml-explicit-end":
    dumped = yaml.safe_dump({'alpha': 1}, explicit_end=True)
    assert dumped.endswith('...\n')
    print(dumped.splitlines()[-1])
elif case_id == "usage-python3-yaml-csafe-sequence":
    loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
    data = yaml.load('- 1\n- 2\n', Loader=loader)
    assert data == [1, 2]
    print(data)
elif case_id == "usage-python3-yaml-base-loader-bool-string":
    data = yaml.load('flag: true\n', Loader=yaml.BaseLoader)
    assert data['flag'] == 'true'
    print(data['flag'])
elif case_id == "usage-python3-yaml-safe-roundtrip-list":
    payload = ['alpha', 'beta', 'gamma']
    dumped = yaml.safe_dump(payload)
    assert yaml.safe_load(dumped) == payload
    print(len(payload))
else:
    raise SystemExit(f"unknown libyaml extra usage case: {case_id}")
PY
