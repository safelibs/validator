#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-tag-directive-batch17
# @title: PyYAML yaml.dump emits a %TAG directive when tags mapping is supplied
# @description: Calls yaml.dump with explicit_start=True and a tags={'!ex!': 'tag:example.com,2026:'} parameter and verifies the output contains a %TAG directive line mapping the !ex! handle to the provided URI prefix and that the document is still parseable by SafeLoader.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-tag-directive-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

data = {"name": "alpha", "count": 3}
text = yaml.dump(
    data,
    Dumper=yaml.SafeDumper,
    explicit_start=True,
    default_flow_style=False,
    sort_keys=True,
    tags={"!ex!": "tag:example.com,2026:"},
)

# %TAG directive must be present and bound to the requested handle/prefix.
assert "%TAG !ex! tag:example.com,2026:" in text, text
# Document marker line follows the directive.
assert "---" in text, text
# Body content survived.
assert "name: alpha" in text, text
assert "count: 3" in text, text

# Document is still parseable; the directive is non-fatal even with no
# tagged scalars in the body.
loaded = yaml.safe_load(text)
assert loaded == data, loaded

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "%TAG !ex! tag:example.com,2026:"
validator_assert_contains "$tmpdir/out.yaml" "name: alpha"
echo "OK"
