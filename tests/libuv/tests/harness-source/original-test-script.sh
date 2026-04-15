#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker_image="${LIBUV_TEST_ORIGINAL_IMAGE:-ubuntu:24.04}"
docker_env=()

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

if [[ -n "${LIBUV_SAFE_DEB_DIR:-}" ]]; then
  if [[ "${LIBUV_SAFE_DEB_DIR}" = /* ]]; then
    safe_deb_dir_host="$(realpath "${LIBUV_SAFE_DEB_DIR}")"
  else
    safe_deb_dir_host="$(realpath "${repo_root}/${LIBUV_SAFE_DEB_DIR}")"
  fi

  [[ -d "${safe_deb_dir_host}" ]] || fail "LIBUV_SAFE_DEB_DIR does not exist: ${LIBUV_SAFE_DEB_DIR}"
  case "${safe_deb_dir_host}" in
    "${repo_root}"/*) ;;
    *) fail "LIBUV_SAFE_DEB_DIR must resolve inside ${repo_root}: ${safe_deb_dir_host}" ;;
  esac

  safe_deb_dir_repo_rel="${safe_deb_dir_host#${repo_root}/}"
  [[ -f "${safe_deb_dir_host}/artifacts.env" ]] || fail "missing artifacts manifest: ${safe_deb_dir_host}/artifacts.env"
  docker_env+=(-e "LIBUV_SAFE_DEB_DIR_REPO_REL=${safe_deb_dir_repo_rel}")
fi

docker run --rm -i \
  --mount "type=bind,src=${repo_root},target=/work,readonly" \
  "${docker_env[@]}" \
  "${docker_image}" \
  bash -s -- <<'EOF'
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
dispatcher_args=(--probes-root /work/safe/tests/dependents --mode full)

note() {
  printf '\n==> %s\n' "$*"
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

install_dependencies() {
  [[ -f /work/safe/docker/ubuntu-src.sources ]] || fail "missing shared source list asset"
  [[ -f /work/safe/docker/dependents-packages.txt ]] || fail "missing shared dependency package list"

  note "Enabling Ubuntu source repositories"
  cp /work/safe/docker/ubuntu-src.sources /etc/apt/sources.list.d/ubuntu-src.sources

  note "Installing test dependencies"
  apt-get update
  xargs -r apt-get install -y --no-install-recommends </work/safe/docker/dependents-packages.txt
}

configure_libuv_mode() {
  if [[ -n "${LIBUV_SAFE_DEB_DIR_REPO_REL:-}" ]]; then
    local manifest

    manifest="/work/${LIBUV_SAFE_DEB_DIR_REPO_REL}/artifacts.env"
    [[ -f "${manifest}" ]] || fail "missing artifacts manifest in container: ${manifest}"
    # shellcheck disable=SC1090
    . "${manifest}"

    [[ -n "${LIBUV_SAFE_RUNTIME_DEB_REPO_REL:-}" ]] || fail "LIBUV_SAFE_RUNTIME_DEB_REPO_REL missing from ${manifest}"
    [[ -n "${LIBUV_SAFE_DEV_DEB_REPO_REL:-}" ]] || fail "LIBUV_SAFE_DEV_DEB_REPO_REL missing from ${manifest}"
    [[ -f "/work/${LIBUV_SAFE_RUNTIME_DEB_REPO_REL}" ]] || fail "runtime package missing: /work/${LIBUV_SAFE_RUNTIME_DEB_REPO_REL}"
    [[ -f "/work/${LIBUV_SAFE_DEV_DEB_REPO_REL}" ]] || fail "development package missing: /work/${LIBUV_SAFE_DEV_DEB_REPO_REL}"

    note "Installing locally built safe libuv packages"
    dpkg -i "/work/${LIBUV_SAFE_RUNTIME_DEB_REPO_REL}" "/work/${LIBUV_SAFE_DEV_DEB_REPO_REL}"
    dispatcher_args+=(--assert-packaged-libuv)
    return
  fi

  note "Building the original libuv"
  cmake -S /work/original -B /tmp/libuv-build \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/opt/libuv-original
  cmake --build /tmp/libuv-build -j"$(nproc)"
  cmake --install /tmp/libuv-build

  export LD_LIBRARY_PATH="/opt/libuv-original/lib"
  export CPPFLAGS="-I/opt/libuv-original/include"
  export LDFLAGS="-L/opt/libuv-original/lib -Wl,-rpath,/opt/libuv-original/lib"
  export PKG_CONFIG_PATH="/opt/libuv-original/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
  dispatcher_args+=(
    --expected-libuv-path /opt/libuv-original/lib/libuv.so.1
    --ld-library-path /opt/libuv-original/lib
  )
}

install_dependencies
configure_libuv_mode

note "Running manifest-backed dependent probes"
bash /work/safe/docker/run-dependent-probes.sh "${dispatcher_args[@]}"
EOF
