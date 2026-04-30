#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-width-10-force-wrap-batch16
# @title: PyYAML yaml.dump with width=10 force-wraps long strings
# @description: Dumps a mapping containing a long whitespace-bearing string with yaml.dump(width=10) and verifies the emitter wraps the value across multiple lines while still round-tripping back to the original string under safe_load.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-width-10-force-wrap-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

original = "alpha beta gamma delta epsilon zeta eta theta iota kappa"
data = {"phrase": original}

text = yaml.dump(data, width=10, default_flow_style=False)

# A width-10 emitter cannot fit "alpha beta gamma ..." on one line,
# so the value must span multiple physical lines.
lines = text.splitlines()
assert len(lines) >= 3, repr(text)

# At least one line must be a continuation (no key on it).
continuations = [ln for ln in lines if ln and not ln.lstrip().startswith("phrase:") and ":" not in ln.split(" ", 1)[0]]
assert continuations, repr(text)

# Round-trip: a YAML 1.1 plain scalar folds wrapped lines back into a
# single space-joined string.
loaded = yaml.safe_load(text)
assert loaded == {"phrase": original}, loaded

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("LINES", len(lines))
print("OK")
PYCASE

# Verify the file actually contains more than one line.
line_count=$(wc -l <"$tmpdir/out.yaml")
if [[ "$line_count" -lt 2 ]]; then
  echo "expected wrapped output to span multiple lines, got $line_count" >&2
  cat "$tmpdir/out.yaml" >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out.yaml" "phrase:"
echo "OK"
