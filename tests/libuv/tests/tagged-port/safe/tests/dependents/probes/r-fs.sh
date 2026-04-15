#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing R fs package"
  Rscript -e 'tmp <- tempfile(); fs::dir_create(tmp); f <- fs::path(tmp, "file.txt"); fs::file_create(f); stopifnot(fs::file_exists(f))'
}

main "$@"
