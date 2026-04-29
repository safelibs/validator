#!/usr/bin/env bash
# @testcase: usage-python3-yaml-documents
# @title: PyYAML documents
# @description: Runs PyYAML documents behavior through libyaml.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; docs=list(yaml.safe_load_all('---\na: 1\n---\nb: 2\n')); print(len(docs))
PY
