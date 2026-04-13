#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
TRIPLET="$(gcc -print-multiarch)"
STAGE="$ROOT/safe/target/stage"

export PATH="$STAGE/usr/bin:$PATH"
export PKG_CONFIG_PATH="$STAGE/usr/lib/$TRIPLET/pkgconfig"
export LD_LIBRARY_PATH="$STAGE/usr/lib/$TRIPLET:${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="$STAGE/usr/lib/$TRIPLET:${LIBRARY_PATH:-}"
export C_INCLUDE_PATH="$STAGE/usr/include/libxml2:${C_INCLUDE_PATH:-}"
export PYTHONPATH="$STAGE/usr/lib/python3/dist-packages:${PYTHONPATH:-}"

cd "$ROOT/original"
make -f Makefile.tests check
