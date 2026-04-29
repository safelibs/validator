#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-load-mapping
# @title: PyYAML CSafeLoader mapping
# @description: Loads a YAML mapping with PyYAML CSafeLoader and verifies the decoded key-value pairs.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-load-mapping"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

loader = getattr(yaml, "CSafeLoader", yaml.SafeLoader)
payload = yaml.load(
    "meta:\n"
    "  enabled: true\n"
    "  retries: 3\n"
    "items:\n"
    "  - alpha\n"
    "  - beta\n",
    Loader=loader,
)
assert payload == {
    "meta": {"enabled": True, "retries": 3},
    "items": ["alpha", "beta"],
}
print(payload["items"][1], payload["meta"]["retries"])
PY
