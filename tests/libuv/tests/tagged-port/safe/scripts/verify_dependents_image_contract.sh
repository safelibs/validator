#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --image <tag> --deb-dir <dir>" >&2
  exit 64
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

image=""
deb_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      [[ $# -ge 2 ]] || usage
      image="$2"
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

[[ -n "${image}" && -n "${deb_dir}" ]] || usage

manifest_path="${deb_dir}/artifacts.env"
[[ -f "${manifest_path}" ]] || fail "missing artifacts manifest: ${manifest_path}"

# shellcheck disable=SC1090
. "${manifest_path}"

[[ -n "${LIBUV_SAFE_RUNTIME_DEB:-}" && -f "${LIBUV_SAFE_RUNTIME_DEB}" ]] || \
  fail "missing runtime package from ${manifest_path}"
[[ -n "${LIBUV_SAFE_DEV_DEB:-}" && -f "${LIBUV_SAFE_DEV_DEB}" ]] || \
  fail "missing development package from ${manifest_path}"

runtime_line="$(printf '%s\t%s\t%s' \
  "$(dpkg-deb -f "${LIBUV_SAFE_RUNTIME_DEB}" Package)" \
  "$(dpkg-deb -f "${LIBUV_SAFE_RUNTIME_DEB}" Version)" \
  "$(dpkg-deb -f "${LIBUV_SAFE_RUNTIME_DEB}" Architecture)")"
dev_line="$(printf '%s\t%s\t%s' \
  "$(dpkg-deb -f "${LIBUV_SAFE_DEV_DEB}" Package)" \
  "$(dpkg-deb -f "${LIBUV_SAFE_DEV_DEB}" Version)" \
  "$(dpkg-deb -f "${LIBUV_SAFE_DEV_DEB}" Architecture)")"

actual_metadata="$(
docker run --rm -i --entrypoint bash "${image}" <<'EOF'
set -euo pipefail
[[ -x /usr/local/bin/run-dependent-probes.sh ]]
dpkg-query -W -f='${Package}\t${Version}\t${Architecture}\n' libuv1t64 libuv1-dev
EOF
)"

expected_metadata="$(printf '%s\n%s\n' "${runtime_line}" "${dev_line}" | sort)"
actual_metadata="$(printf '%s\n' "${actual_metadata}" | sort)"

[[ "${actual_metadata}" = "${expected_metadata}" ]] || {
  printf 'expected image metadata:\n%s\n' "${expected_metadata}" >&2
  printf 'actual image metadata:\n%s\n' "${actual_metadata}" >&2
  fail "dependent image metadata does not match artifacts.env"
}
