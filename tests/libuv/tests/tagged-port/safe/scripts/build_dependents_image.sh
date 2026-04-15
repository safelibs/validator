#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --tag <tag> --deb-dir <dir>" >&2
  exit 64
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

tag=""
deb_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      [[ $# -ge 2 ]] || usage
      tag="$2"
      shift 2
      ;;
    --deb-dir)
      [[ $# -ge 2 ]] || usage
      deb_dir="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[[ -n "${tag}" && -n "${deb_dir}" ]] || usage

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
safe_root="$(cd "${script_dir}/.." && pwd)"
manifest_path="${deb_dir}/artifacts.env"

[[ -f "${manifest_path}" ]] || fail "missing artifacts manifest: ${manifest_path}"

# shellcheck disable=SC1090
. "${manifest_path}"

[[ -n "${LIBUV_SAFE_RUNTIME_DEB:-}" && -f "${LIBUV_SAFE_RUNTIME_DEB}" ]] || \
  fail "missing runtime package from ${manifest_path}"
[[ -n "${LIBUV_SAFE_DEV_DEB:-}" && -f "${LIBUV_SAFE_DEV_DEB}" ]] || \
  fail "missing development package from ${manifest_path}"

build_context="$(mktemp -d)"
trap 'rm -rf "${build_context}"' EXIT

mkdir -p "${build_context}/docker" "${build_context}/debs"

install -m 0644 "${safe_root}/docker/Dockerfile.dependents" "${build_context}/Dockerfile.dependents"
install -m 0755 "${safe_root}/docker/run-dependent-probes.sh" "${build_context}/docker/run-dependent-probes.sh"
install -m 0644 "${safe_root}/docker/dependents-packages.txt" "${build_context}/docker/dependents-packages.txt"
install -m 0644 "${safe_root}/docker/ubuntu-src.sources" "${build_context}/docker/ubuntu-src.sources"
install -m 0644 "${LIBUV_SAFE_RUNTIME_DEB}" "${build_context}/debs/libuv-runtime.deb"
install -m 0644 "${LIBUV_SAFE_DEV_DEB}" "${build_context}/debs/libuv-dev.deb"

docker build --pull --no-cache \
  -t "${tag}" \
  -f "${build_context}/Dockerfile.dependents" \
  "${build_context}"
