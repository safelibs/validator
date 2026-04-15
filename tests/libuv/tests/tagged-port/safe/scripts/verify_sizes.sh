#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <stage-prefix>" >&2
  exit 64
fi

stage_prefix="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
safe_root="$(cd "${script_dir}/.." && pwd)"
tmp_build="$(mktemp -d /tmp/libuv-safe-sizes.XXXXXX)"
trap 'rm -rf "${tmp_build}"' EXIT

"${script_dir}/build_upstream_harness.sh" --stage "${stage_prefix}" --build "${tmp_build}"

python3 - "${safe_root}" "${tmp_build}" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

safe_root = Path(sys.argv[1])
build_dir = Path(sys.argv[2])
baseline = json.loads((safe_root / "tools/abi-baseline.json").read_text())
expected = baseline["linux_x86_64"]["sizes_benchmark_bytes"]

pattern = re.compile(r"^(uv_[A-Za-z0-9_]+): (\d+) bytes$")

for binary_name in ("uv_safe_benchmark_sizes_shared", "uv_safe_benchmark_sizes_static"):
    output = subprocess.check_output(
        [str(build_dir / binary_name)],
        text=True,
        stderr=subprocess.STDOUT,
    )
    seen = {}
    for line in output.splitlines():
        match = pattern.match(line.strip())
        if match:
            seen[match.group(1)] = int(match.group(2))

    if seen != expected:
        missing = sorted(set(expected) - set(seen))
        mismatch = sorted(k for k in expected if k in seen and seen[k] != expected[k])
        extra = sorted(set(seen) - set(expected))
        if missing:
            raise SystemExit(f"{binary_name}: missing size lines for {', '.join(missing)}")
        if mismatch:
            details = ", ".join(f"{name}={seen[name]} expected {expected[name]}" for name in mismatch)
            raise SystemExit(f"{binary_name}: size mismatches: {details}")
        if extra:
            raise SystemExit(f"{binary_name}: unexpected extra size lines: {', '.join(extra)}")

print("verified benchmark size probe output for shared and static harnesses")
PY
