#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

if case_id == 'usage-python3-yaml-flow-sequence-nested-batch11':
    data = yaml.safe_load('root: [[1, 2], [3, 4]]')
    assert data['root'][1][0] == 3
    print(data['root'])
elif case_id == 'usage-python3-yaml-dump-sort-keys-false-batch11':
    text = yaml.safe_dump({'b': 1, 'a': 2}, sort_keys=False)
    assert text.splitlines()[0].startswith('b:')
    print(text, end='')
elif case_id == 'usage-python3-yaml-quoted-colon-string-batch11':
    data = yaml.safe_load('value: "alpha: beta"')
    assert data['value'] == 'alpha: beta'
    print(data['value'])
elif case_id == 'usage-python3-yaml-block-chomp-strip-batch11':
    data = yaml.safe_load('value: |-\n  alpha\n  beta\n')
    assert data['value'] == 'alpha\nbeta'
    print(data['value'])
elif case_id == 'usage-python3-yaml-csafe-flow-set-batch11':
    data = yaml.load('!!set {alpha: null, beta: null}', Loader=yaml.CSafeLoader)
    assert data == {'alpha', 'beta'}
    print(sorted(data))
elif case_id == 'usage-python3-yaml-compose-document-tag-batch11':
    node = yaml.compose('value: 7')
    assert node.tag.endswith(':map')
    print(node.tag)
elif case_id == 'usage-python3-yaml-scan-stream-tokens-batch11':
    tokens = list(yaml.scan('a: 1\n'))
    names = [type(token).__name__ for token in tokens]
    assert 'StreamStartToken' in names and 'StreamEndToken' in names
    print(','.join(names))
elif case_id == 'usage-python3-yaml-parse-event-order-batch11':
    events = [type(event).__name__ for event in yaml.parse('- a\n- b\n')]
    assert events[0] == 'StreamStartEvent'
    assert 'SequenceStartEvent' in events
    print(','.join(events))
elif case_id == 'usage-python3-yaml-safe-dump-all-three-batch11':
    text = yaml.safe_dump_all([{'a': 1}, {'b': 2}, {'c': 3}], explicit_start=True)
    assert text.count('---') == 3
    print(text, end='')
elif case_id == 'usage-python3-yaml-custom-dice-resolver-batch11':
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
else:
    raise SystemExit(f'unknown libyaml eleventh-batch usage case: {case_id}')
PYCASE
