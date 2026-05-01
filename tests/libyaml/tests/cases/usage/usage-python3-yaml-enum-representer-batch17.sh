#!/usr/bin/env bash
# @testcase: usage-python3-yaml-enum-representer-batch17
# @title: PyYAML add_multi_representer routes an enum.Enum subclass to its name
# @description: Defines an enum.Enum subclass, registers SafeDumper.add_multi_representer against enum.Enum that emits each member as its .name string, and verifies the dumped YAML lists the enum names verbatim and round-trips through yaml.safe_load to the corresponding plain strings.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-enum-representer-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import enum
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

class Color(enum.Enum):
    RED = 1
    GREEN = 2
    BLUE = 3

class EnumDumper(yaml.SafeDumper):
    pass

def represent_enum(dumper, member):
    return dumper.represent_scalar("tag:yaml.org,2002:str", member.name)

# add_multi_representer dispatches on isinstance against any Enum subclass.
EnumDumper.add_multi_representer(enum.Enum, represent_enum)

palette = [Color.RED, Color.GREEN, Color.BLUE]
text = yaml.dump(palette, Dumper=EnumDumper, default_flow_style=False)

assert "- RED" in text, text
assert "- GREEN" in text, text
assert "- BLUE" in text, text

# Round-trip through SafeLoader yields plain str names.
loaded = yaml.safe_load(text)
assert loaded == ["RED", "GREEN", "BLUE"], loaded
assert all(isinstance(x, str) for x in loaded), loaded

# Without the multi-representer, the default SafeDumper would refuse the
# enum because it's an unknown type.
try:
    yaml.dump(palette[0], Dumper=yaml.SafeDumper)
except yaml.representer.RepresenterError:
    pass
else:
    raise AssertionError("plain SafeDumper unexpectedly serialized an Enum")

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "- RED"
validator_assert_contains "$tmpdir/out.yaml" "- GREEN"
validator_assert_contains "$tmpdir/out.yaml" "- BLUE"
echo "OK"
