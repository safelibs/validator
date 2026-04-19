#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; loader=getattr(yaml,'CSafeLoader',yaml.SafeLoader); data=yaml.load('value: 42\n', Loader=loader); print(data['value'])
PY