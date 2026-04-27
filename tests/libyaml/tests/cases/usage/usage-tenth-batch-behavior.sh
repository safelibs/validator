#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-yaml-safe-load-octal-int)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('answer: 017\n')
print(value['answer'])
PYCASE
    validator_assert_contains "$tmpdir/out" '15'
    ;;
  usage-python3-yaml-safe-load-negative-float)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('value: -2.5\n')
print(value['value'])
PYCASE
    validator_assert_contains "$tmpdir/out" '-2.5'
    ;;
  usage-python3-yaml-safe-load-flow-mapping)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('{alpha: 1, beta: 2}')
print(value['alpha'], value['beta'])
PYCASE
    validator_assert_contains "$tmpdir/out" '1 2'
    ;;
  usage-python3-yaml-safe-load-no-bool)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('flag: no\n')
print(value['flag'])
PYCASE
    validator_assert_contains "$tmpdir/out" 'False'
    ;;
  usage-python3-yaml-safe-load-nested-list)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('matrix:\n  - [1, 2]\n  - [3, 4]\n')
print(value['matrix'][1][0], value['matrix'][1][1])
PYCASE
    validator_assert_contains "$tmpdir/out" '3 4'
    ;;
  usage-python3-yaml-safe-dump-flow-style)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
text = yaml.safe_dump({'items': [1, 2, 3]}, default_flow_style=True)
print(text, end='')
PYCASE
    validator_assert_contains "$tmpdir/out" '[1, 2, 3]'
    ;;
  usage-python3-yaml-safe-dump-multiline-indent)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
text = yaml.safe_dump({'tree': {'leaf': 'value'}}, indent=4)
print(text, end='')
PYCASE
    validator_assert_contains "$tmpdir/out" '    leaf: value'
    ;;
  usage-python3-yaml-csafe-load-anchor-alias)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
value = yaml.load('first: &one alpha\nsecond: *one\n', Loader=loader)
print(value['first'], value['second'])
PYCASE
    validator_assert_contains "$tmpdir/out" 'alpha alpha'
    ;;
  usage-python3-yaml-safe-load-all-three-docs)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
docs = list(yaml.safe_load_all('---\n1\n---\n2\n---\n3\n'))
print(','.join(str(d) for d in docs))
PYCASE
    validator_assert_contains "$tmpdir/out" '1,2,3'
    ;;
  usage-python3-yaml-scan-token-types)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
tokens = list(yaml.scan('key: value\n'))
names = [type(t).__name__ for t in tokens]
print('|'.join(names))
PYCASE
    validator_assert_contains "$tmpdir/out" 'StreamStartToken'
    validator_assert_contains "$tmpdir/out" 'ScalarToken'
    ;;
  *)
    printf 'unknown libyaml tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
