#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml

case_id = sys.argv[1]
tmpdir = sys.argv[2]

if case_id == "usage-python3-yaml-safe-load-nested-map":
    payload = yaml.safe_load("root:\n  child:\n    value: 7\n")
    assert payload["root"]["child"]["value"] == 7
    print(payload["root"]["child"]["value"])
elif case_id == "usage-python3-yaml-safe-dump-width":
    text = yaml.safe_dump({"letters": ["alpha", "beta", "gamma"]}, width=20)
    assert "letters" in text and "alpha" in text
    print(text.strip())
elif case_id == "usage-python3-yaml-safe-load-bool-list":
    payload = yaml.safe_load("- true\n- false\n- true\n")
    assert payload == [True, False, True]
    print(",".join("true" if item else "false" for item in payload))
elif case_id == "usage-python3-yaml-full-load-hex-int":
    payload = yaml.full_load("value: 0x10\n")
    assert payload["value"] == 16
    print(payload["value"])
elif case_id == "usage-python3-yaml-compose-sequence":
    node = yaml.compose("- alpha\n- beta\n")
    assert node.id == "sequence"
    print(node.id, len(node.value))
elif case_id == "usage-python3-yaml-scan-anchor-token":
    tokens = [type(token).__name__ for token in yaml.scan("&anchor value\n")]
    assert "AnchorToken" in tokens
    print(",".join(tokens))
elif case_id == "usage-python3-yaml-parse-alias-event":
    events = [type(event).__name__ for event in yaml.parse("root: &anchor alpha\nref: *anchor\n")]
    assert "AliasEvent" in events
    print(",".join(events))
elif case_id == "usage-python3-yaml-csafe-dump-flow":
    text = yaml.dump({"name": "alpha", "value": 7}, Dumper=yaml.CSafeDumper, default_flow_style=True)
    assert text.startswith("{")
    print(text.strip())
elif case_id == "usage-python3-yaml-csafe-load-mapping":
    payload = yaml.load("name: alpha\nvalue: 7\n", Loader=yaml.CSafeLoader)
    assert payload["name"] == "alpha" and payload["value"] == 7
    print(payload["name"], payload["value"])
elif case_id == "usage-python3-yaml-dump-all-explicit-start":
    text = yaml.dump_all([{"name": "alpha"}, {"name": "beta"}], explicit_start=True)
    assert text.count("---") == 2
    print(text.strip())
else:
    raise SystemExit(f"unknown libyaml additional usage case: {case_id}")
PY
