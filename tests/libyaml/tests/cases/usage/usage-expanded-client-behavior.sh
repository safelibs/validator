#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-yaml-safe-load-folded-scalar)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('message: >\n  alpha\n  beta\n')
print(value['message'].strip())
PYCASE
    validator_assert_contains "$tmpdir/out" 'alpha beta'
    ;;
  usage-python3-yaml-safe-load-literal-scalar)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('message: |\n  alpha\n  beta\n')
print(repr(value['message']))
PYCASE
    validator_assert_contains "$tmpdir/out" "\\n"
    ;;
  usage-python3-yaml-safe-load-hex-int)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('answer: 0x10\n')
print(value['answer'])
PYCASE
    validator_assert_contains "$tmpdir/out" '16'
    ;;
  usage-python3-yaml-safe-load-float-inf)
    python3 >"$tmpdir/out" <<'PYCASE'
import math
import yaml
value = yaml.safe_load('answer: .inf\n')
print(math.isinf(value['answer']))
PYCASE
    validator_assert_contains "$tmpdir/out" 'True'
    ;;
  usage-python3-yaml-safe-dump-explicit-start)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
print(yaml.safe_dump({'name': 'validator'}, explicit_start=True), end='')
PYCASE
    validator_assert_contains "$tmpdir/out" '---'
    ;;
  usage-python3-yaml-safe-dump-allow-unicode)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
print(yaml.safe_dump({'word': 'cafe'}, allow_unicode=True), end='')
PYCASE
    validator_assert_contains "$tmpdir/out" 'word: cafe'
    ;;
  usage-python3-yaml-csafe-load-binary-bytes)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
value = yaml.load('payload: !!binary Zm9v\n', Loader=loader)
print(value['payload'])
PYCASE
    validator_assert_contains "$tmpdir/out" "b'foo'"
    ;;
  usage-python3-yaml-compose-sequence-length)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
node = yaml.compose('[1, 2, 3]')
print(len(node.value))
PYCASE
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-python3-yaml-parse-event-count)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
events = list(yaml.parse('alpha: 1\nbeta: 2\n'))
print(len(events))
PYCASE
    grep -Eq '^[0-9]+$' "$tmpdir/out"
    ;;
  usage-python3-yaml-safe-load-yes-bool)
    python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('flag: yes\n')
print(value['flag'])
PYCASE
    validator_assert_contains "$tmpdir/out" 'True'
    ;;
  *)
    printf 'unknown libyaml expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
