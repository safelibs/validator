#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

if case_id == "usage-python3-yaml-safe-load-nested-map":
    payload = yaml.safe_load(
        "root:\n"
        "  child:\n"
        "    flag: true\n"
        "    items:\n"
        "      - 7\n"
        "      - 9\n"
    )
    assert payload == {"root": {"child": {"flag": True, "items": [7, 9]}}}
    assert isinstance(payload["root"]["child"]["flag"], bool)
    print(payload["root"]["child"]["items"][1])
elif case_id == "usage-python3-yaml-safe-dump-width":
    value = ["alphabet", "betatron", "gammawave", "deltaforce"]
    text = yaml.safe_dump(value, width=20, default_flow_style=True)
    lines = [line for line in text.splitlines() if line]
    assert len(lines) >= 2
    assert lines[1].startswith("  ")
    assert yaml.safe_load(text) == value
    print(len(lines), lines[1])
elif case_id == "usage-python3-yaml-safe-load-bool-list":
    payload = yaml.safe_load("- true\n- false\n- true\n")
    assert payload == [True, False, True]
    assert [type(item).__name__ for item in payload] == ["bool", "bool", "bool"]
    print(",".join("true" if item else "false" for item in payload))
elif case_id == "usage-python3-yaml-full-load-hex-int":
    payload = yaml.full_load("value: 0x10\n")
    assert payload["value"] == 16
    assert isinstance(payload["value"], int)
    print(payload["value"])
elif case_id == "usage-python3-yaml-compose-sequence":
    node = yaml.compose("- alpha\n- beta\n")
    assert node.tag == "tag:yaml.org,2002:seq"
    assert [child.value for child in node.value] == ["alpha", "beta"]
    print(node.tag)
elif case_id == "usage-python3-yaml-scan-anchor-token":
    tokens = list(yaml.scan("root: &anchor alpha\nref: *anchor\n"))
    names = [type(token).__name__ for token in tokens]
    assert any(isinstance(token, AnchorToken) and token.value == "anchor" for token in tokens)
    assert any(isinstance(token, AliasToken) and token.value == "anchor" for token in tokens)
    assert any(isinstance(token, ScalarToken) and token.value == "alpha" for token in tokens)
    print(",".join(names))
elif case_id == "usage-python3-yaml-parse-alias-event":
    events = list(yaml.parse("root: &anchor alpha\nref: *anchor\n"))
    names = [type(event).__name__ for event in events]
    assert any(isinstance(event, MappingStartEvent) for event in events)
    assert any(isinstance(event, AliasEvent) and event.anchor == "anchor" for event in events)
    scalar_values = [event.value for event in events if isinstance(event, ScalarEvent)]
    assert scalar_values == ["root", "alpha", "ref"]
    print(",".join(names))
elif case_id == "usage-python3-yaml-csafe-dump-flow":
    dumper = getattr(yaml, "CSafeDumper", yaml.SafeDumper)
    loader = getattr(yaml, "CSafeLoader", yaml.SafeLoader)
    value = {"name": "alpha", "values": [1, 2]}
    text = yaml.dump(value, Dumper=dumper, default_flow_style=True, sort_keys=False)
    assert text.startswith("{")
    assert yaml.load(text, Loader=loader) == value
    print(text.strip())
elif case_id == "usage-python3-yaml-csafe-load-mapping":
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
elif case_id == "usage-python3-yaml-dump-all-explicit-start":
    docs = [{"name": "alpha"}, {"name": "beta"}]
    text = yaml.dump_all(docs, explicit_start=True, sort_keys=False)
    assert text.startswith("---")
    assert text.count("---") == 2
    assert list(yaml.safe_load_all(text)) == docs
    print(text.count("---"))
else:
    raise SystemExit(f"unknown libyaml additional usage case: {case_id}")
PY
