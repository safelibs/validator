#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 <stage-prefix>" >&2
  exit 64
}

fail() {
  echo "$*" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage

stage_prefix="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
safe_root="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${safe_root}/.." && pwd)"
original_include="${repo_root}/original/include"
stage_include="${stage_prefix}/include"
pc_path="${stage_prefix}/lib/pkgconfig"

[[ -d "${stage_prefix}" ]] || fail "missing stage prefix: ${stage_prefix}"
[[ -d "${stage_prefix}/lib" ]] || fail "missing staged lib directory: ${stage_prefix}/lib"
[[ -d "${pc_path}" ]] || fail "missing staged pkg-config directory: ${pc_path}"

[[ -L "${stage_prefix}/lib/libuv.so" ]] || fail "missing symlink: ${stage_prefix}/lib/libuv.so"
[[ -L "${stage_prefix}/lib/libuv.so.1" ]] || fail "missing symlink: ${stage_prefix}/lib/libuv.so.1"
[[ -f "${stage_prefix}/lib/libuv.so.1.0.0" ]] || fail "missing shared object: ${stage_prefix}/lib/libuv.so.1.0.0"
[[ -f "${stage_prefix}/lib/libuv.a" ]] || fail "missing static archive: ${stage_prefix}/lib/libuv.a"
[[ -f "${stage_prefix}/lib/pkgconfig/libuv.pc" ]] || fail "missing pkg-config file: ${stage_prefix}/lib/pkgconfig/libuv.pc"
[[ -f "${stage_prefix}/lib/pkgconfig/libuv-static.pc" ]] || fail "missing pkg-config file: ${stage_prefix}/lib/pkgconfig/libuv-static.pc"

[[ "$(readlink "${stage_prefix}/lib/libuv.so")" == "libuv.so.1" ]] || fail "libuv.so must point to libuv.so.1"
[[ "$(readlink "${stage_prefix}/lib/libuv.so.1")" == "libuv.so.1.0.0" ]] || fail "libuv.so.1 must point to libuv.so.1.0.0"

[[ -f "${stage_include}/uv.h" ]] || fail "missing staged header: ${stage_include}/uv.h"
cmp -s "${original_include}/uv.h" "${stage_include}/uv.h" || fail "header mismatch: uv.h"

while IFS= read -r -d '' original_header; do
  relative_path="${original_header#${original_include}/}"
  staged_header="${stage_include}/${relative_path}"
  [[ -f "${staged_header}" ]] || fail "missing staged header: ${staged_header}"
  cmp -s "${original_header}" "${staged_header}" || fail "header mismatch: ${relative_path}"
done < <(find "${original_include}/uv" -type f -print0 | sort -z)

diff -ruN "${original_include}" "${stage_include}" >/dev/null || fail "staged headers differ from original/include"

temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

cat >"${temp_dir}/stage-smoke.c" <<'EOF'
#include <uv.h>

int main(void) {
  return uv_version() == 0 || uv_version_string() == NULL;
}
EOF

PKG_CONFIG_PATH="${pc_path}" \
  cc "${temp_dir}/stage-smoke.c" -o "${temp_dir}/stage-smoke-dynamic" \
  $(PKG_CONFIG_PATH="${pc_path}" pkg-config --cflags --libs libuv)

LD_LIBRARY_PATH="${stage_prefix}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" \
  "${temp_dir}/stage-smoke-dynamic"

PKG_CONFIG_PATH="${pc_path}" \
  cc "${temp_dir}/stage-smoke.c" -o "${temp_dir}/stage-smoke-static" \
  $(PKG_CONFIG_PATH="${pc_path}" pkg-config --cflags --libs --static libuv-static)

"${temp_dir}/stage-smoke-static"
