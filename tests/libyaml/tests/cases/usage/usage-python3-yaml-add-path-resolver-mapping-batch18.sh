#!/usr/bin/env bash
# @testcase: usage-python3-yaml-add-path-resolver-mapping-batch18
# @title: PyYAML yaml.add_path_resolver retags a scalar at a fixed mapping path
# @description: Calls yaml.add_path_resolver to register a "!secret" tag that fires whenever a scalar is loaded as the value of the "password" key at the document root, and binds a constructor for !secret that wraps the raw text. Verifies that the path-located scalar receives the custom tag (its constructed value is wrapped) while a sibling key at the same level retains the default string tag.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-add-path-resolver-mapping-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

class SecretLoader(yaml.SafeLoader):
    pass

# Path resolver: a scalar reached by following the "password" key from the
# document root must implicitly receive the !secret tag.
yaml.add_path_resolver("!secret", ["password"], kind=str, Loader=SecretLoader)

def construct_secret(loader, node):
    raw = loader.construct_scalar(node)
    return f"<<{raw}>>"

SecretLoader.add_constructor("!secret", construct_secret)

doc = (
    "user: alice\n"
    "password: hunter2\n"
    "note: keep it secret keep it safe\n"
)

data = yaml.load(doc, Loader=SecretLoader)

# The path-resolved scalar is dispatched through the !secret constructor.
assert data["password"] == "<<hunter2>>", data
# Sibling keys at the same depth keep their default string resolution.
assert data["user"] == "alice", data
assert data["note"] == "keep it secret keep it safe", data
assert isinstance(data["user"], str), type(data["user"])

# A plain SafeLoader without the path resolver loads the same field as a
# bare string -- proving the path resolver was actually responsible for the
# retag above.
plain = yaml.safe_load(doc)
assert plain["password"] == "hunter2", plain
assert plain["user"] == "alice", plain

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"password={data['password']}\n")
    fh.write(f"plain_password={plain['password']}\n")
    fh.write(f"user={data['user']}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "password=<<hunter2>>"
validator_assert_contains "$tmpdir/out" "plain_password=hunter2"
validator_assert_contains "$tmpdir/out" "user=alice"
echo "OK"
