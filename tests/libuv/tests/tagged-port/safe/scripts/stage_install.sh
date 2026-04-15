#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 4 ]]; then
  echo "usage: $0 <stage-prefix> [install-prefix] [libdir] [includedir]" >&2
  exit 64
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
safe_root="$(cd "${script_dir}/.." && pwd)"
stage_prefix="$1"
install_prefix="${2:-${LIBUV_STAGE_INSTALL_PREFIX:-${stage_prefix}}}"
artifact_dir="${safe_root}/target/release"
shared_src="${artifact_dir}/libuv.so"
static_src="${artifact_dir}/libuv.a"
libdir="${3:-${LIBUV_STAGE_LIBDIR:-\${exec_prefix}/lib}}"
includedir="${4:-${LIBUV_STAGE_INCLUDEDIR:-\${prefix}/include}}"

if [[ ! -f "${shared_src}" || ! -f "${static_src}" ]]; then
  echo "cargo build --release must succeed before staging artifacts" >&2
  exit 1
fi

mkdir -p "${stage_prefix}/include" "${stage_prefix}/lib/pkgconfig"
cp -a "${safe_root}/include/." "${stage_prefix}/include/"
install -m 0644 "${static_src}" "${stage_prefix}/lib/libuv.a"
install -m 0755 "${shared_src}" "${stage_prefix}/lib/libuv.so.1.0.0"
ln -sfn "libuv.so.1.0.0" "${stage_prefix}/lib/libuv.so.1"
ln -sfn "libuv.so.1" "${stage_prefix}/lib/libuv.so"

repo_root="$(cd "${safe_root}/.." && pwd)"

python3 - "${repo_root}" "${safe_root}" "${stage_prefix}" "${install_prefix}" "${libdir}" "${includedir}" <<'PY'
import json
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
safe_root = Path(sys.argv[2])
stage_prefix = Path(sys.argv[3])
install_prefix = sys.argv[4]
libdir = sys.argv[5]
includedir = sys.argv[6]
baseline = json.loads((safe_root / "tools/abi-baseline.json").read_text())
linux = baseline["linux_x86_64"]
version = linux["pkg_config"]["version"]
libs = " ".join(linux["pkg_config"]["libs"])
substitutions = {
    "@prefix@": str(install_prefix),
    "@libdir@": libdir,
    "@includedir@": includedir,
    "@PACKAGE_VERSION@": version,
    "@LIBS@": libs,
}

templates = [
    (repo_root / "original/libuv.pc.in", stage_prefix / "lib/pkgconfig/libuv.pc"),
    (repo_root / "original/libuv-static.pc.in", stage_prefix / "lib/pkgconfig/libuv-static.pc"),
]

for src, dst in templates:
    content = src.read_text()
    for old, new in substitutions.items():
        content = content.replace(old, new)
    dst.write_text(content)
PY
