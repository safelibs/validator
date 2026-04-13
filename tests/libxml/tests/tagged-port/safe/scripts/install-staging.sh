#!/usr/bin/env bash
set -euo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SELF_DIR/../../safe/Cargo.toml" ]]; then
  WORKTREE_ROOT="$(cd -- "$SELF_DIR/../.." && pwd)"
  SOURCE_ROOT="$WORKTREE_ROOT/safe"
elif [[ -f "$SELF_DIR/../Cargo.toml" ]]; then
  WORKTREE_ROOT="$(cd -- "$SELF_DIR/.." && pwd)"
  SOURCE_ROOT="$WORKTREE_ROOT"
else
  printf 'failed to resolve safe source root from %s\n' "$SELF_DIR" >&2
  exit 1
fi

if [[ -d "$SOURCE_ROOT/original" ]]; then
  ORIGINAL_ROOT="$SOURCE_ROOT/original"
elif [[ -d "$WORKTREE_ROOT/original" ]]; then
  ORIGINAL_ROOT="$WORKTREE_ROOT/original"
else
  printf 'missing required original/ assets next to %s\n' "$SOURCE_ROOT" >&2
  exit 1
fi

STAGE="${1:-$SOURCE_ROOT/target/stage}"
if [[ "$STAGE" != /* ]]; then
  STAGE="$WORKTREE_ROOT/$STAGE"
fi
ARTIFACTS_ENV="$SOURCE_ROOT/target/build-artifacts.env"
RELEASE_BINDIR="$SOURCE_ROOT/target/release"

ensure_release_artifacts() {
  RUSTFLAGS="${RUSTFLAGS:-} -C relocation-model=pic" \
    cargo rustc --manifest-path "$SOURCE_ROOT/Cargo.toml" --release --lib --crate-type staticlib
  cargo build --manifest-path "$SOURCE_ROOT/Cargo.toml" --release --bins
}

ensure_release_artifacts

# shellcheck disable=SC1090
source "$ARTIFACTS_ENV"

TRIPLET="${LIBXML2_TRIPLET:-$(gcc -print-multiarch)}"
LIBDIR="$STAGE/usr/lib/$TRIPLET"
BINDIR="$STAGE/usr/bin"
INCLUDEROOT="$STAGE/usr/include/libxml2"
INCLUDEDIR="$INCLUDEROOT/libxml"
PKGDIR="$LIBDIR/pkgconfig"
ACLOCALDIR="$STAGE/usr/share/aclocal"
MAN1DIR="$STAGE/usr/share/man/man1"
MAN3DIR="$STAGE/usr/share/man/man3"
PYTHONDIR="$STAGE/usr/lib/python3/dist-packages"

rm -rf "$STAGE"
mkdir -p "$LIBDIR" "$BINDIR" "$INCLUDEDIR" "$PKGDIR" "$ACLOCALDIR" "$MAN1DIR" "$MAN3DIR" "$PYTHONDIR"

cp "$LIBXML2_NATIVE_STATIC" "$LIBDIR/libxml2.a"
cc -shared \
  -Wl,--no-undefined \
  -Wl,-soname,libxml2.so.2 \
  -Wl,--version-script,"$SOURCE_ROOT/abi/libxml2.syms" \
  -o "$LIBDIR/libxml2.so.$LIBXML2_VERSION" \
  -Wl,--whole-archive \
  "$LIBXML2_NATIVE_STATIC" \
  -Wl,--no-whole-archive \
  -lz -llzma -lm -ldl -lpthread
ln -s "libxml2.so.$LIBXML2_VERSION" "$LIBDIR/libxml2.so.2"
ln -s "libxml2.so.2" "$LIBDIR/libxml2.so"

install -m 0644 "$SOURCE_ROOT/include/config.h" "$INCLUDEROOT/config.h"
cp -a "$SOURCE_ROOT/include/libxml/." "$INCLUDEDIR/"
cp "$SOURCE_ROOT/share/aclocal/libxml2.m4" "$ACLOCALDIR/libxml2.m4"

cat >"$PKGDIR/libxml-2.0.pc" <<EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib/$TRIPLET
includedir=\${prefix}/include
modules=1

Name: libXML
Version: $LIBXML2_VERSION
Description: libXML library version2.
Requires:
Libs: -L\${libdir} -lxml2
Libs.private: -lz -llzma -lm -ldl -lpthread
Cflags: -I\${includedir}/libxml2
EOF

cat >"$LIBDIR/xml2Conf.sh" <<EOF
#
# Configuration file for using the XML library in GNOME applications
#
XML2_LIBDIR="-L/usr/lib/$TRIPLET"
XML2_LIBS="-lxml2 -lz  -llzma   -lm "
XML2_INCLUDEDIR="-I/usr/include/libxml2"
MODULE_VERSION="xml2-$LIBXML2_VERSION"
EOF

cat >"$BINDIR/xml2-config" <<EOF
#!/usr/bin/env bash
set -euo pipefail

prefix=/usr
exec_prefix=\${prefix}
includedir=\${prefix}/include
libdir=\${exec_prefix}/lib/$TRIPLET
cflags=
libs=

usage() {
  cat <<USAGE
Usage: xml2-config [OPTION]

Known values for OPTION are:

  --prefix=DIR        change libxml prefix [default \$prefix]
  --exec-prefix=DIR   change libxml exec prefix [default \$exec_prefix]
  --libs              print library dynamic linking information
  --cflags            print pre-processor and compiler flags
  --modules           module support enabled
  --help              display this help and exit
  --version           output version information
USAGE
  exit "\${1:-0}"
}

if [[ \$# -eq 0 ]]; then
  usage 1
fi

while [[ \$# -gt 0 ]]; do
  case "\$1" in
    --prefix=*)
      prefix="\${1#*=}"
      includedir="\$prefix/include"
      libdir="\$prefix/lib/$TRIPLET"
      ;;
    --prefix)
      printf '%s\n' "\$prefix"
      ;;
    --exec-prefix=*)
      exec_prefix="\${1#*=}"
      libdir="\$exec_prefix/lib/$TRIPLET"
      ;;
    --exec-prefix)
      printf '%s\n' "\$exec_prefix"
      ;;
    --version)
      printf '%s\n' "$LIBXML2_VERSION"
      exit 0
      ;;
    --help)
      usage 0
      ;;
    --cflags)
      cflags="-I\${includedir}/libxml2"
      ;;
    --libtool-libs)
      :
      ;;
    --modules)
      printf '1\n'
      ;;
    --libs)
      libs="-lxml2"
      ;;
    *)
      usage 1
      ;;
  esac
  shift
done

if [[ -n "\$cflags\$libs" ]]; then
  printf '%s\n' "\$cflags \$libs" | xargs
fi
EOF
chmod +x "$BINDIR/xml2-config"
install -m 0755 "$RELEASE_BINDIR/xmllint" "$BINDIR/xmllint"
install -m 0755 "$RELEASE_BINDIR/xmlcatalog" "$BINDIR/xmlcatalog"
install -m 0644 "$ORIGINAL_ROOT/doc/xmllint.1" "$MAN1DIR/xmllint.1"
install -m 0644 "$ORIGINAL_ROOT/doc/xmlcatalog.1" "$MAN1DIR/xmlcatalog.1"
install -m 0644 "$ORIGINAL_ROOT/xml2-config.1" "$MAN1DIR/xml2-config.1"
install -m 0644 "$ORIGINAL_ROOT/libxml.3" "$MAN3DIR/libxml.3"

make -C "$SOURCE_ROOT/python" \
  STAGE="$STAGE" \
  TRIPLET="$TRIPLET" \
  PYTHON=python3 \
  install
