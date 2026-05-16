#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-load-all-document-order-preserved
# @title: PyYAML safe_load_all yields multi-document scalars in the order they appear in the stream
# @description: Feeds a three-document YAML stream with distinct integer scalars to yaml.safe_load_all and asserts list(safe_load_all(...)) equals the source order — pinning libyaml's multi-doc parsing order through python3-yaml.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load-all, multidoc, order, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

stream = """\
--- 7
--- 11
--- 13
"""
docs = list(yaml.safe_load_all(stream))
assert docs == [7, 11, 13], docs
PY
