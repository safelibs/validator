#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
safe_dir=$(cd -- "$script_dir/.." && pwd)
dockerfile="$safe_dir/docker/dependents.Dockerfile"
image_tag="${LIBSODIUM_DEPENDENT_IMAGE:-${LIBSODIUM_ORIGINAL_TEST_IMAGE:-libsodium-original-test:ubuntu24.04}}"

usage() {
  cat <<EOF
usage: $(basename "$0") [--tag <tag>]

Builds the Ubuntu 24.04 dependent-harness image from safe/docker/dependents.Dockerfile.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($#)); do
  case "$1" in
    --tag)
      image_tag="${2:?missing value for --tag}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

command -v docker >/dev/null 2>&1 || die "docker is required to run $(basename "$0")"
[[ -f "$dockerfile" ]] || die "missing Dockerfile: $dockerfile"

docker build -t "$image_tag" -f "$dockerfile" "$safe_dir/docker"
