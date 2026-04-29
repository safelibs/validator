#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-dumper
# @title: PyYAML csafe dumper
# @description: Runs PyYAML csafe dumper behavior through libyaml.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; dumper=getattr(yaml,'CSafeDumper',yaml.SafeDumper); print(yaml.dump({'value':42}, Dumper=dumper))
PY
