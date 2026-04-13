#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/safe/target/debs"
INSIDE_CURRENT_ENV=0
MIN_RUST_VERSION="1.82.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --inside-current-env)
      INSIDE_CURRENT_ENV=1
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

prepare_snapshot() {
  local dest="$1"

  mkdir -p "$dest"
  if git -C "$ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$ROOT" ls-files -z -- safe original \
      | tar -C "$ROOT" --null -T - -cf - \
      | tar -xf - -C "$dest"
  else
    tar \
      -C "$ROOT" \
      --exclude='safe/target' \
      --exclude='safe/debian/.debhelper' \
      --exclude='safe/debian/files' \
      --exclude='safe/debian/tmp' \
      -cf - \
      safe \
      original \
      | tar -xf - -C "$dest"
  fi

  rm -rf "$dest/safe/original"
  cp -a "$dest/original" "$dest/safe/original"
}

collect_artifacts() {
  local build_root="$1"

  find "$build_root" -maxdepth 1 -type f \
    \( \
      -name '*.deb' \
      -o -name '*.changes' \
      -o -name '*.buildinfo' \
      -o -name 'libxml2_*.dsc' \
      -o -name 'libxml2_*.debian.tar.*' \
      -o -name 'libxml2_*.orig.tar.*' \
    \) \
    -exec cp -f '{}' "$OUT/" \;
}

verify_dev_package_static_archive() {
  local matches

  mapfile -t matches < <(find "$OUT" -maxdepth 1 -type f -name 'libxml2-dev_*.deb' | sort)
  if [[ "${#matches[@]}" -ne 1 ]]; then
    printf 'expected exactly one libxml2-dev .deb under %s\n' "$OUT" >&2
    exit 1
  fi
  if ! dpkg-deb -c "${matches[0]}" | grep -E '/usr/lib/.*/libxml2\.a$' >/dev/null; then
    printf 'libxml2-dev package is missing /usr/lib/*/libxml2.a: %s\n' "${matches[0]}" >&2
    exit 1
  fi
}

require_single_output() {
  local pattern="$1"
  local label="$2"
  local matches

  mapfile -t matches < <(find "$OUT" -maxdepth 1 -type f -name "$pattern" | sort)
  if [[ "${#matches[@]}" -ne 1 ]]; then
    printf 'expected exactly one %s under %s (pattern %s)\n' "$label" "$OUT" "$pattern" >&2
    exit 1
  fi
}

verify_output_contract() {
  local arch
  local package

  arch="$(dpkg --print-architecture)"
  for package in libxml2 libxml2-dev libxml2-utils python3-libxml2; do
    require_single_output "${package}_*.deb" "${package} binary package"
  done

  require_single_output 'libxml2_*.dsc' 'source package descriptor'
  require_single_output 'libxml2_*.debian.tar.*' 'debian source tarball'
  require_single_output 'libxml2_*.orig.tar.*' 'orig source tarball'
  require_single_output 'libxml2_*_source.buildinfo' 'source buildinfo'
  require_single_output 'libxml2_*_source.changes' 'source changes'
  require_single_output "libxml2_*_${arch}.buildinfo" 'binary buildinfo'
  require_single_output "libxml2_*_${arch}.changes" 'binary changes'
}

ensure_orig_tarball() {
  local build_root="$1"
  local version
  local upstream_version
  local tarball

  version="$(dpkg-parsechangelog -l"$build_root/safe/debian/changelog" -SVersion)"
  upstream_version="${version%-*}"
  tarball="$build_root/libxml2_${upstream_version}.orig.tar.xz"

  if [[ -f "$tarball" ]]; then
    return
  fi

  tar \
    -C "$build_root" \
    --exclude='safe/debian' \
    --exclude='safe/target' \
    -cJf "$tarball" \
    --transform="s,^safe,libxml2-${upstream_version}," \
    safe
}

reset_output_dir() {
  if rm -rf "$OUT" 2>/dev/null; then
    mkdir -p "$OUT"
    return
  fi

  docker run --rm \
    -v "$ROOT:$ROOT" \
    ubuntu:24.04 \
    bash -lc "rm -rf '$OUT'"

  rm -rf "$OUT"
  mkdir -p "$OUT"
}

fix_tree_ownership() {
  local tree_root="$1"

  docker run --rm \
    -v "$tree_root:/work" \
    ubuntu:24.04 \
    bash -lc "chown -R $(id -u):$(id -g) /work"
}

run_build() {
  local mode="$1"
  local build_root
  local status

  build_root="$(mktemp -d)"
  prepare_snapshot "$build_root"
  if ! (
    cd "$build_root/safe"
    case "$mode" in
      source)
        ensure_orig_tarball "$build_root"
        dpkg-buildpackage -S -us -uc -sa
        ;;
      binary)
        dpkg-buildpackage -b -us -uc
        ;;
      *)
        printf 'unknown build mode: %s\n' "$mode" >&2
        exit 1
        ;;
    esac
  ); then
    status=$?
    rm -rf "$build_root"
    return "$status"
  fi
  collect_artifacts "$build_root"
  rm -rf "$build_root"
}

run_inside_current_env() {
  ensure_modern_rust_toolchain
  rm -rf "$OUT"
  mkdir -p "$OUT"

  run_build source
  run_build binary
  verify_output_contract
  verify_dev_package_static_archive
}

ensure_modern_rust_toolchain() {
  local current_version

  current_version="$(rustc --version 2>/dev/null | awk '{print $2}' || true)"
  if [[ -n "$current_version" ]] && dpkg --compare-versions "$current_version" ge "$MIN_RUST_VERSION"; then
    return
  fi

  if ! command -v curl >/dev/null 2>&1; then
    printf 'missing required tool for rustup bootstrap: curl\n' >&2
    exit 1
  fi

  export RUSTUP_HOME="${RUSTUP_HOME:-$ROOT/safe/target/rustup-home}"
  export CARGO_HOME="${CARGO_HOME:-$ROOT/safe/target/cargo-home}"
  export PATH="$CARGO_HOME/bin:$PATH"

  if [[ ! -x "$CARGO_HOME/bin/rustc" ]]; then
    mkdir -p "$RUSTUP_HOME" "$CARGO_HOME"
    curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal --default-toolchain stable --no-modify-path
  fi

  current_version="$(rustc --version 2>/dev/null | awk '{print $2}' || true)"
  if [[ -z "$current_version" ]] || ! dpkg --compare-versions "$current_version" ge "$MIN_RUST_VERSION"; then
    printf 'failed to provision rustc >= %s, found %s\n' "$MIN_RUST_VERSION" "${current_version:-missing}" >&2
    exit 1
  fi
}

run_in_docker() {
  local snapshot_root
  local status

  if ! command -v docker >/dev/null 2>&1; then
    printf 'missing required host tool: docker\n' >&2
    exit 1
  fi

  snapshot_root="$(mktemp -d)"
  prepare_snapshot "$snapshot_root"

  status=0
  docker run --rm \
    -e DEBIAN_FRONTEND=noninteractive \
    -v "$snapshot_root:/work" \
    -w /work \
    ubuntu:24.04 \
    bash -lc "sed 's/^Types: deb\$/Types: deb-src/' /etc/apt/sources.list.d/ubuntu.sources > /etc/apt/sources.list.d/ubuntu-src.sources && apt-get update >/tmp/build-deb-bootstrap.log && apt-get install -y --no-install-recommends ca-certificates curl dpkg-dev git python3 >/tmp/build-deb-bootstrap-install.log && apt-get build-dep -y /work/safe >/tmp/build-deb-builddep.log && /work/safe/scripts/build-deb.sh --inside-current-env" || status=$?
  fix_tree_ownership "$snapshot_root"
  if [[ "$status" -ne 0 ]]; then
    rm -rf "$snapshot_root"
    return "$status"
  fi

  reset_output_dir
  cp -a "$snapshot_root/safe/target/debs/." "$OUT/"
  rm -rf "$snapshot_root"
  verify_output_contract
  verify_dev_package_static_archive

  return "$status"
}

if [[ "$INSIDE_CURRENT_ENV" -eq 1 ]]; then
  run_inside_current_env
else
  run_in_docker
fi
