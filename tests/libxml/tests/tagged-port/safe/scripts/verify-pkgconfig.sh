#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGE="$(cd -- "$1" && pwd)"
BASELINE_PKGCONFIG="$2"
BASELINE_XML2_CONFIG="$3"
BASELINE_XML2CONF="$4"
TRIPLET="$(gcc -print-multiarch)"

export PATH="$STAGE/usr/bin:$PATH"
export PKG_CONFIG_PATH="$STAGE/usr/lib/$TRIPLET/pkgconfig"
export LD_LIBRARY_PATH="$STAGE/usr/lib/$TRIPLET:${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="$STAGE/usr/lib/$TRIPLET:${LIBRARY_PATH:-}"
export C_INCLUDE_PATH="$STAGE/usr/include/libxml2:${C_INCLUDE_PATH:-}"
export PYTHONPATH="$STAGE/usr/lib/python3/dist-packages:${PYTHONPATH:-}"

normalize() {
  sed "s#/lib/$TRIPLET#/lib#g" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//'
}

normalize_xml2conf() {
  sed "s#/lib/$TRIPLET#/lib#g" "$1" | sed '/^$/d' | tr -s ' ' | sed 's/ $//'
}

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

pkg-config --cflags --libs libxml-2.0 | normalize >"$TMPDIR/pkgconfig.txt"
xml2-config --cflags --libs | normalize >"$TMPDIR/xml2-config.txt"
normalize_xml2conf "$STAGE/usr/lib/$TRIPLET/xml2Conf.sh" >"$TMPDIR/xml2Conf.sh.txt"

normalize <"$BASELINE_PKGCONFIG" >"$TMPDIR/baseline-pkgconfig.txt"
normalize <"$BASELINE_XML2_CONFIG" >"$TMPDIR/baseline-xml2-config.txt"
normalize_xml2conf "$BASELINE_XML2CONF" >"$TMPDIR/baseline-xml2Conf.sh.txt"

diff -u "$TMPDIR/baseline-pkgconfig.txt" "$TMPDIR/pkgconfig.txt"
diff -u "$TMPDIR/baseline-xml2-config.txt" "$TMPDIR/xml2-config.txt"
diff -u "$TMPDIR/baseline-xml2Conf.sh.txt" "$TMPDIR/xml2Conf.sh.txt"
