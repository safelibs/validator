#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
safe_root="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${safe_root}/.." && pwd)"
dist_dir="${safe_root}/dist"
abi_baseline="${safe_root}/tools/abi-baseline.json"
runtime_pkg="libuv1t64"
dev_pkg="libuv1-dev"

rm -rf "${dist_dir}"
mkdir -p "${dist_dir}"

unset LD_PRELOAD

cargo build --release --manifest-path "${safe_root}/Cargo.toml"

"${safe_root}/tools/verify_exports.sh" \
  "${safe_root}/target/release/libuv.so" \
  "${repo_root}/original/build-checker/libuv.so.1.0.0" \
  "${repo_root}/original/debian/libuv1t64.symbols"

python3 "${safe_root}/tools/render_debian_symbols.py" \
  "${abi_baseline}" \
  "${repo_root}/original/debian/libuv1t64.symbols" \
  "${safe_root}/debian/libuv1t64.symbols"

(
  cd "${safe_root}"
  dpkg-buildpackage -us -uc -b -tc
)

version="$(dpkg-parsechangelog -l"${safe_root}/debian/changelog" -SVersion)"
arch="$(dpkg-architecture -qDEB_HOST_ARCH)"
runtime_src="${repo_root}/${runtime_pkg}_${version}_${arch}.deb"
dev_src="${repo_root}/${dev_pkg}_${version}_${arch}.deb"

[[ -f "${runtime_src}" ]] || {
  echo "missing runtime package: ${runtime_src}" >&2
  exit 1
}
[[ -f "${dev_src}" ]] || {
  echo "missing development package: ${dev_src}" >&2
  exit 1
}

mv "${runtime_src}" "${dist_dir}/"
mv "${dev_src}" "${dist_dir}/"

runtime_deb="$(realpath "${dist_dir}/$(basename "${runtime_src}")")"
dev_deb="$(realpath "${dist_dir}/$(basename "${dev_src}")")"
runtime_repo_rel="${runtime_deb#${repo_root}/}"
dev_repo_rel="${dev_deb#${repo_root}/}"
runtime_package="$(dpkg-deb -f "${runtime_deb}" Package)"
runtime_version="$(dpkg-deb -f "${runtime_deb}" Version)"
runtime_arch="$(dpkg-deb -f "${runtime_deb}" Architecture)"
dev_package="$(dpkg-deb -f "${dev_deb}" Package)"
dev_version="$(dpkg-deb -f "${dev_deb}" Version)"
dev_arch="$(dpkg-deb -f "${dev_deb}" Architecture)"

[[ "${runtime_package}" = "${runtime_pkg}" ]] || {
  echo "unexpected runtime package name: ${runtime_package}" >&2
  exit 1
}
[[ "${dev_package}" = "${dev_pkg}" ]] || {
  echo "unexpected development package name: ${dev_package}" >&2
  exit 1
}

artifacts_tmp="$(mktemp "${dist_dir}/artifacts.env.XXXXXX")"

cat >"${artifacts_tmp}" <<EOF
LIBUV_SAFE_RUNTIME_DEB=${runtime_deb}
LIBUV_SAFE_DEV_DEB=${dev_deb}
LIBUV_SAFE_RUNTIME_DEB_REPO_REL=${runtime_repo_rel}
LIBUV_SAFE_DEV_DEB_REPO_REL=${dev_repo_rel}
LIBUV_SAFE_RUNTIME_PACKAGE=${runtime_package}
LIBUV_SAFE_RUNTIME_VERSION=${runtime_version}
LIBUV_SAFE_RUNTIME_ARCH=${runtime_arch}
LIBUV_SAFE_DEV_PACKAGE=${dev_package}
LIBUV_SAFE_DEV_VERSION=${dev_version}
LIBUV_SAFE_DEV_ARCH=${dev_arch}
EOF

mv "${artifacts_tmp}" "${dist_dir}/artifacts.env"
