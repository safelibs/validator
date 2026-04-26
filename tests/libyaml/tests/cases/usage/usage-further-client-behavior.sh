#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-yaml-safe-load-set)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('items: !!set {alpha: null, beta: null}\n')
print(','.join(sorted(value['items'])))
PYCASE
    validator_assert_contains "$tmpdir/out" 'alpha,beta'
    ;;
  usage-python3-yaml-safe-load-null-list)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('[null, ~, value]\n')
print(value[0] is None, value[1] is None, value[2])
PYCASE
    validator_assert_contains "$tmpdir/out" 'True True value'
    ;;
  usage-python3-yaml-full-load-timestamp)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.full_load('when: 2024-01-02\n')
print(value['when'].isoformat())
PYCASE
    validator_assert_contains "$tmpdir/out" '2024-01-02'
    ;;
  usage-python3-yaml-base-loader-null-string)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
loader = getattr(yaml, 'CBaseLoader', yaml.BaseLoader)
value = yaml.load('value: null\n', Loader=loader)
print(value['value'])
PYCASE
    validator_assert_contains "$tmpdir/out" 'null'
    ;;
  usage-python3-yaml-csafe-load-bool-map)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
value = yaml.load('alpha: true\nbeta: false\n', Loader=loader)
print(value['alpha'], value['beta'])
PYCASE
    validator_assert_contains "$tmpdir/out" 'True False'
    ;;
  usage-python3-yaml-safe-dump-default-style)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
text = yaml.safe_dump({'items': [1, 2]}, sort_keys=False)
print(text, end='')
PYCASE
    validator_assert_contains "$tmpdir/out" 'items:'
    validator_assert_contains "$tmpdir/out" '- 1'
    ;;
  usage-python3-yaml-safe-dump-list-indent)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
docs = list(yaml.compose_all('---\na: 1\n---\nb: 2\n'))
print(len(docs), docs[0].value[0][0].value, docs[1].value[0][0].value)
PYCASE
    validator_assert_contains "$tmpdir/out" '2 a b'
    ;;
  usage-python3-yaml-compose-scalar-tag)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
node = yaml.compose('answer: 42\n')
_key_node, value_node = node.value[0]
print(value_node.tag)
PYCASE
    validator_assert_contains "$tmpdir/out" 'int'
    ;;
  usage-python3-yaml-safe-load-ordered-keys)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('alpha: 1\nbeta: 2\ngamma: 3\n')
print(','.join(value.keys()))
PYCASE
    validator_assert_contains "$tmpdir/out" 'alpha,beta,gamma'
    ;;
  usage-python3-yaml-csafe-dump-explicit-end)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
dumper = getattr(yaml, 'CSafeDumper', yaml.SafeDumper)
text = yaml.dump_all([{'a': 1}, {'b': 2}], Dumper=dumper, explicit_end=True)
print(text, end='')
PYCASE
    validator_assert_contains "$tmpdir/out" '...'
    ;;
  *)
    printf 'unknown libyaml further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
