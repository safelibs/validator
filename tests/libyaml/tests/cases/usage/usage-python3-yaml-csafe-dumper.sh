#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; dumper=getattr(yaml,'CSafeDumper',yaml.SafeDumper); print(yaml.dump({'value':42}, Dumper=dumper))
PY