#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
safe_dir=$(cd -- "$script_dir/.." && pwd)
repo_dir=$(cd -- "$safe_dir/.." && pwd)

rm -f \
  "$repo_dir"/libsodium23_*.deb \
  "$repo_dir"/libsodium-dev_*.deb \
  "$repo_dir"/libsodium23-dbgsym_*.ddeb \
  "$repo_dir"/libsodium23-dbgsym_*.deb \
  "$repo_dir"/libsodium-dbgsym_*.deb \
  "$repo_dir"/*.buildinfo \
  "$repo_dir"/*.changes

rm -rf \
  "$safe_dir"/debian/.debhelper \
  "$safe_dir"/debian/libsodium-dev \
  "$safe_dir"/debian/libsodium23 \
  "$safe_dir"/debian/tmp

rm -f \
  "$safe_dir"/debian/debhelper-build-stamp \
  "$safe_dir"/debian/files \
  "$safe_dir"/debian/libsodium-dev.substvars \
  "$safe_dir"/debian/libsodium23.substvars

(
  cd "$safe_dir"
  dpkg-buildpackage -us -uc -b
)
