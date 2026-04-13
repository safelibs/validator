#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_TAG="${LIBXML_ORIGINAL_TEST_IMAGE:-libxml-original-test:ubuntu24.04}"
PACKAGE_MODE="${LIBXML_PACKAGE_MODE:-original}"
PREBUILT_DEBS_DIR="${LIBXML_PREBUILT_DEBS_DIR:-}"
BUILD_CONTEXT="$(mktemp -d)"
EXPECTED_SAFE_PACKAGES=(
  libxml2
  libxml2-dev
  libxml2-utils
  python3-libxml2
)

cleanup() {
  rm -rf "$BUILD_CONTEXT"
}

trap cleanup EXIT

for tool in docker git; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'missing required host tool: %s\n' "$tool" >&2
    exit 1
  fi
done

if [[ ! -d "$ROOT/original" ]]; then
  printf 'missing original source tree\n' >&2
  exit 1
fi

if [[ ! -f "$ROOT/dependents.json" ]]; then
  printf 'missing dependents.json\n' >&2
  exit 1
fi

resolve_prebuilt_debs_dir() {
  local debs_dir="$PREBUILT_DEBS_DIR"

  if [[ "$PACKAGE_MODE" != "safe" ]]; then
    return
  fi

  if [[ -z "$debs_dir" ]]; then
    printf 'LIBXML_PREBUILT_DEBS_DIR must be set when LIBXML_PACKAGE_MODE=safe\n' >&2
    exit 1
  fi

  if [[ "$debs_dir" != /* ]]; then
    debs_dir="$ROOT/$debs_dir"
  fi

  if [[ ! -d "$debs_dir" ]]; then
    printf 'LIBXML_PREBUILT_DEBS_DIR does not exist: %s\n' "$debs_dir" >&2
    exit 1
  fi

  PREBUILT_DEBS_DIR="$(cd -- "$debs_dir" && pwd)"
}

require_prebuilt_safe_debs() {
  local package="$1"
  local matches=()

  mapfile -t matches < <(find "$PREBUILT_DEBS_DIR" -maxdepth 1 -type f -name "${package}_*.deb" | sort)
  if [[ "${#matches[@]}" -ne 1 ]]; then
    printf 'expected exactly one %s .deb under %s\n' "$package" "$PREBUILT_DEBS_DIR" >&2
    exit 1
  fi
}

copy_prebuilt_debs_into_context() {
  local package

  if [[ "$PACKAGE_MODE" != "safe" ]]; then
    return
  fi

  mkdir -p "$BUILD_CONTEXT/prebuilt-debs"
  for package in "${EXPECTED_SAFE_PACKAGES[@]}"; do
    require_prebuilt_safe_debs "$package"
    cp -f "$PREBUILT_DEBS_DIR"/"${package}"_*.deb "$BUILD_CONTEXT/prebuilt-debs/"
  done
}

resolve_prebuilt_debs_dir
git ls-files -z -- original safe dependents.json | tar --null -T - -cf - | tar -xf - -C "$BUILD_CONTEXT"
copy_prebuilt_debs_into_context

docker build -t "$IMAGE_TAG" -f - "$BUILD_CONTEXT" <<'DOCKERFILE'
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN sed 's/^Types: deb$/Types: deb-src/' /etc/apt/sources.list.d/ubuntu.sources \
      > /etc/apt/sources.list.d/ubuntu-src.sources \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      cyrus-admin \
      cyrus-caldav \
      cyrus-imapd \
      dbus-x11 \
      dpkg-dev \
      kdoctools5 \
      liblzma-dev \
      libvirt-clients \
      libvirt-daemon \
      libxml2-dev \
      mariadb-client \
      mariadb-plugin-connect \
      mariadb-server \
      netcat-openbsd \
      ninja-build \
      openbox \
      php8.3-cli \
      php8.3-xml \
      postgresql-16 \
      procps \
      python3 \
      python3-lxml \
      pkg-config \
      sasl2-bin \
      xclip \
      xdotool \
      xauth \
      xmlstarlet \
      xvfb \
      yelp \
      yelp-tools \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

COPY . /work
WORKDIR /work
DOCKERFILE

docker run --rm -i \
  -e LIBXML_PACKAGE_MODE="$PACKAGE_MODE" \
  -e LIBXML_PREBUILT_DEBS_DIR="${PREBUILT_DEBS_DIR:+/work/prebuilt-debs}" \
  "$IMAGE_TAG" \
  bash <<'CONTAINER_SCRIPT'
set -euo pipefail

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

ROOT=/work
SRC_ROOT=/tmp/libxml-original
PACKAGE_MODE="${LIBXML_PACKAGE_MODE:-original}"
PREBUILT_DEBS_DIR="${LIBXML_PREBUILT_DEBS_DIR:-}"
EXPECTED_SAFE_PACKAGES=(
  libxml2
  libxml2-dev
  libxml2-utils
  python3-libxml2
)

log_step() {
  printf '\n==> %s\n' "$1"
}

require_contains() {
  local path="$1"
  local needle="$2"

  if ! grep -F -- "$needle" "$path" >/dev/null 2>&1; then
    printf 'missing expected text in %s: %s\n' "$path" "$needle" >&2
    printf -- '--- %s ---\n' "$path" >&2
    cat "$path" >&2
    exit 1
  fi
}

require_nonempty_file() {
  local path="$1"

  if [[ ! -s "$path" ]]; then
    printf 'expected non-empty file: %s\n' "$path" >&2
    exit 1
  fi
}

validate_dependents_inventory() {
  python3 <<'PY'
import json
from pathlib import Path

expected = [
    "libvirt-daemon",
    "postgresql-16",
    "php8.3-xml",
    "python3-lxml",
    "xmlstarlet",
    "mariadb-plugin-connect",
    "cyrus-caldav",
    "yelp",
    "libobt2v5",
    "kdoctools5",
    "yelp-tools",
    "llvm-toolchain-18",
]

data = json.loads(Path("/work/dependents.json").read_text(encoding="utf-8"))
actual = [entry["name"] for entry in data["dependents"]]

if actual != expected:
    raise SystemExit(
        f"unexpected dependents.json contents: expected {expected}, found {actual}"
    )
PY
}

build_original_libxml() {
  log_step "Building original libxml"
  cp -a "$ROOT/original" "$SRC_ROOT"
  cd "$SRC_ROOT"
  ./configure --prefix=/usr/local --disable-static --without-python >/tmp/libxml-configure.log 2>&1
  make -j"$(nproc)" >/tmp/libxml-make.log 2>&1
  make install >/tmp/libxml-install.log 2>&1
  printf '/usr/local/lib\n' > /etc/ld.so.conf.d/zz-libxml-local.conf
  ldconfig
  cd /
}

resolve_local_deb() {
  local package="$1"
  local matches=()

  mapfile -t matches < <(find "$PREBUILT_DEBS_DIR" -maxdepth 1 -type f -name "${package}_*.deb" | sort)
  if [[ "${#matches[@]}" -ne 1 ]]; then
    printf 'expected exactly one %s .deb under %s\n' "$package" "$PREBUILT_DEBS_DIR" >&2
    exit 1
  fi

  printf '%s\n' "${matches[0]}"
}

install_prebuilt_safe_packages() {
  local package
  local deb_path
  local version

  log_step "Installing prebuilt safe libxml2 Debian packages"
  if [[ -z "$PREBUILT_DEBS_DIR" ]]; then
    printf 'LIBXML_PREBUILT_DEBS_DIR must be set when LIBXML_PACKAGE_MODE=safe\n' >&2
    exit 1
  fi
  if [[ ! -d "$PREBUILT_DEBS_DIR" ]]; then
    printf 'LIBXML_PREBUILT_DEBS_DIR does not exist in container: %s\n' "$PREBUILT_DEBS_DIR" >&2
    exit 1
  fi

  apt-get update
  for package in "${EXPECTED_SAFE_PACKAGES[@]}"; do
    deb_path="$(resolve_local_deb "$package")"
    apt-get install -y --no-install-recommends "$deb_path"
    version="$(dpkg-deb -f "$deb_path" Version)"
    if [[ "$(dpkg-query -W -f='${Version}' "$package")" != "$version" ]]; then
      printf 'installed version mismatch for %s after installing %s\n' "$package" "$deb_path" >&2
      exit 1
    fi
  done
}

installed_package_libxml2_paths() {
  dpkg-query -L libxml2 | grep -E '^/(usr/)?lib/.*/libxml2\.so\.2$' | sort -u
}

binary_libxml2_path() {
  local log_path="$1"

  awk '/libxml2\.so\.2[[:space:]]*=>/ { print $3; exit }' "$log_path"
}

assert_binary_uses_expected_libxml() {
  local binary="$1"
  local log_path="$2"
  local actual
  local candidate

  ldd "$binary" > "$log_path"
  if [[ "$PACKAGE_MODE" != "safe" ]]; then
    require_contains "$log_path" "/usr/local/lib/libxml2.so.2"
    return
  fi

  actual="$(binary_libxml2_path "$log_path")"
  if [[ -z "$actual" ]]; then
    printf 'failed to determine loaded libxml2 path for %s\n' "$binary" >&2
    printf -- '--- %s ---\n' "$log_path" >&2
    cat "$log_path" >&2
    exit 1
  fi

  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    if [[ "$actual" == "$candidate" ]]; then
      return
    fi
    if [[ "$(readlink -f -- "$actual")" == "$(readlink -f -- "$candidate")" ]]; then
      return
    fi
  done < <(installed_package_libxml2_paths)

  printf 'loaded libxml2 path for %s is not owned by the installed replacement package: %s\n' "$binary" "$actual" >&2
  printf 'package candidates were:\n' >&2
  installed_package_libxml2_paths >&2
  printf -- '--- %s ---\n' "$log_path" >&2
  cat "$log_path" >&2
  exit 1
}

assert_selected_libxml_is_used() {
  log_step "Verifying dynamic linker preference"
  assert_binary_uses_expected_libxml "$(command -v xmlstarlet)" /tmp/xmlstarlet-ldd.log
}

test_libvirt_daemon() {
  log_step "libvirt-daemon"
  cat > /tmp/libvirt-domain.xml <<'XML'
<domain type="test">
  <name>smoke</name>
  <memory unit="KiB">1024</memory>
  <currentMemory unit="KiB">1024</currentMemory>
  <vcpu>1</vcpu>
  <os>
    <type arch="x86_64">hvm</type>
  </os>
</domain>
XML

  virsh -c test:///default <<'EOF' > /tmp/libvirt.log
define /tmp/libvirt-domain.xml
dumpxml smoke
quit
EOF

  require_contains /tmp/libvirt.log "Domain 'smoke' defined from /tmp/libvirt-domain.xml"
  require_contains /tmp/libvirt.log "<name>smoke</name>"
  require_contains /tmp/libvirt.log "<type arch='x86_64'>hvm</type>"
}

test_postgresql() {
  log_step "postgresql-16"
  pg_ctlcluster 16 main start
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 -At <<'SQL' > /tmp/postgresql.log
SELECT 'xpath=' || xpath($$//item/text()$$, xmlparse(document $$<root><item>one</item><item>two</item></root>$$))::text;
SELECT 'xmlexists=' || xmlexists($$//item[text()="two"]$$ PASSING BY REF xmlparse(document $$<root><item>one</item><item>two</item></root>$$))::text;
SELECT 'xmlelement=' || xmlelement(name library, xmlattributes('2' AS version), xmlforest('libxml' AS name));
SQL
  pg_ctlcluster 16 main stop

  require_contains /tmp/postgresql.log "xpath={one,two}"
  require_contains /tmp/postgresql.log "xmlexists=true"
  require_contains /tmp/postgresql.log 'xmlelement=<library version="2"><name>libxml</name></library>'
}

test_php_xml() {
  log_step "php8.3-xml"
  php8.3 <<'PHP' > /tmp/php-xml.log
<?php
$doc = new DOMDocument();
$doc->loadXML('<root><item>one</item><item>two</item></root>');
$xpath = new DOMXPath($doc);
echo $xpath->evaluate('string(/root/item[2])'), PHP_EOL;

$reader = new XMLReader();
$reader->XML('<root><item>reader</item></root>');
while ($reader->read()) {
    if ($reader->nodeType === XMLReader::ELEMENT && $reader->name === 'item') {
        $reader->read();
        echo $reader->value, PHP_EOL;
        break;
    }
}

$writer = new XMLWriter();
$writer->openMemory();
$writer->startDocument('1.0', 'UTF-8');
$writer->startElement('root');
$writer->writeElement('item', 'writer');
$writer->endElement();
echo $writer->outputMemory();
PHP

  require_contains /tmp/php-xml.log "two"
  require_contains /tmp/php-xml.log "reader"
  require_contains /tmp/php-xml.log "<item>writer</item>"
}

test_python_lxml() {
  log_step "python3-lxml"
  python3 <<'PY' > /tmp/python-lxml.log
from lxml import etree

xml = etree.XML(b"<root><item>one</item><item>two</item></root>")
print(xml.xpath("string(/root/item[2])"))

xslt = etree.XSLT(
    etree.XML(
        b"""
        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:template match="/">
            <items><xsl:value-of select="count(/root/item)"/></items>
          </xsl:template>
        </xsl:stylesheet>
        """
    )
)
print(str(xslt(xml)))
PY

  require_contains /tmp/python-lxml.log "two"
  require_contains /tmp/python-lxml.log "<items>2</items>"
}

test_xmlstarlet() {
  log_step "xmlstarlet"
  cat > /tmp/xmlstarlet-input.xml <<'XML'
<root>
  <item>one</item>
  <item>two</item>
</root>
XML

  xmlstarlet sel -t -v '/root/item[2]' /tmp/xmlstarlet-input.xml > /tmp/xmlstarlet-select.log
  xmlstarlet ed -u '/root/item[1]' -v 'updated' /tmp/xmlstarlet-input.xml > /tmp/xmlstarlet-edited.xml

  require_contains /tmp/xmlstarlet-select.log "two"
  require_contains /tmp/xmlstarlet-edited.xml "<item>updated</item>"
}

test_mariadb_connect() {
  log_step "mariadb-plugin-connect"
  service mariadb start >/tmp/mariadb-start.log 2>&1
  cat > /tmp/xsample.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<BIBLIO SUBJECT="XML">
  <BOOK ISBN="9782212090819" LANG="fr" SUBJECT="applications">
    <AUTHOR>Jean-Christophe Bernadac</AUTHOR>
    <TITLE>Construire une application XML</TITLE>
    <PUBLISHER>Eyrolles Paris</PUBLISHER>
    <DATEPUB>1999</DATEPUB>
  </BOOK>
  <BOOK ISBN="9782840825685" LANG="fr" SUBJECT="applications">
    <AUTHOR>William J. Pardi</AUTHOR>
    <TITLE>XML en Action</TITLE>
    <PUBLISHER>Microsoft Press Paris</PUBLISHER>
    <DATEPUB>1999</DATEPUB>
  </BOOK>
</BIBLIO>
XML
  chown mysql:mysql /tmp/xsample.xml

  cat > /tmp/mariadb-connect.sql <<'SQL'
CREATE DATABASE IF NOT EXISTS smoke;
USE smoke;
CREATE OR REPLACE TABLE books (
  AUTHOR CHAR(50),
  TITLE CHAR(32),
  PUBLISHER CHAR(40),
  DATEPUB INT(4)
) ENGINE=CONNECT TABLE_TYPE=XML FILE_NAME="/tmp/xsample.xml" OPTION_LIST="xmlsup=libxml2,rownode=BOOK";
SELECT AUTHOR, TITLE, DATEPUB FROM books ORDER BY TITLE;
DROP TABLE books;
SQL

  mysql -uroot < /tmp/mariadb-connect.sql > /tmp/mariadb-connect.log
  service mariadb stop >/tmp/mariadb-stop.log 2>&1 || true

  require_contains /tmp/mariadb-connect.log "Jean-Christophe Bernadac"
  require_contains /tmp/mariadb-connect.log "XML en Action"
}

test_cyrus_caldav() {
  log_step "cyrus-caldav"
  printf 'secret\n' | saslpasswd2 -p -c imapuser >/dev/null
  printf 'mypassword\n' | saslpasswd2 -p -c example >/dev/null
  printf 'admins: imapuser\n' >> /etc/imapd.conf
  sed -i \
    -e 's/^\([[:space:]]*pop3[[:space:]].*\)$/# \1/' \
    -e 's/^\([[:space:]]*nntp[[:space:]].*\)$/# \1/' \
    /etc/cyrus.conf
  mkdir -p /run/cyrus /run/cyrus/socket
  chown cyrus:mail /run/cyrus /run/cyrus/socket
  chmod 755 /run/cyrus
  chmod 750 /run/cyrus/socket
  /usr/sbin/cyrmaster -d -C /etc/imapd.conf -M /etc/cyrus.conf
  sleep 5

  TERM=dumb cyradm -u imapuser -w secret localhost <<'EOF' >/tmp/cyradm.log
createmailbox user.example
quit
EOF

  cat > /tmp/cyrus-propfind.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<propfind xmlns="DAV:">
  <prop>
    <displayname/>
  </prop>
</propfind>
XML

  curl \
    --silent \
    --show-error \
    --user example:mypassword \
    --request PROPFIND \
    --header 'Depth: 1' \
    --header 'Content-Type: application/xml' \
    --data-binary @/tmp/cyrus-propfind.xml \
    --include \
    http://localhost:8008/dav/principals/user/example/ \
    > /tmp/cyrus.log

  kill "$(cat /run/cyrus-master.pid)"
  wait || true

  require_contains /tmp/cyrus.log "HTTP/1.1 207 Multi-Status"
  require_contains /tmp/cyrus.log "<displayname>example</displayname>"
}

test_yelp() {
  log_step "yelp"
  mkdir -p /tmp/yelp-help
  cat > /tmp/yelp-help/index.page <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<page xmlns="http://projectmallard.org/1.0/" type="guide" id="index">
  <info>
    <title type="text">Smoke Help</title>
  </info>
  <title>Smoke Help</title>
  <p>Testing Yelp with Mallard XML.</p>
</page>
XML

  timeout 20 dbus-run-session -- xvfb-run -a bash -lc '
    set -euo pipefail

    printf "" | xclip -selection clipboard
    yelp /tmp/yelp-help/index.page >/tmp/yelp.log 2>&1 &
    yelp_pid=$!

    cleanup() {
      kill "$yelp_pid" 2>/dev/null || true
      wait "$yelp_pid" 2>/dev/null || true
    }

    trap cleanup EXIT
    xdotool search --sync --name "Help" > /tmp/yelp-window.ids
    yelp_window="$(tail -n1 /tmp/yelp-window.ids)"
    sleep 2
    xdotool key --window "$yelp_window" ctrl+a
    sleep 1
    xdotool key --window "$yelp_window" ctrl+c
    sleep 1
    xclip -o -selection clipboard > /tmp/yelp-clipboard.log
  '

  require_nonempty_file /tmp/yelp-window.ids
  require_contains /tmp/yelp-clipboard.log "Smoke Help"
  require_contains /tmp/yelp-clipboard.log "Testing Yelp with Mallard XML."
}

test_libobt() {
  log_step "libobt2v5"
  mkdir -p /tmp/openbox
  cat > /tmp/openbox/rc.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance>
    <strength>42</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
  </focus>
  <placement>
    <policy>UnderMouse</policy>
    <center>yes</center>
    <monitor>Primary</monitor>
    <primaryMonitor>1</primaryMonitor>
  </placement>
  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
  </theme>
  <desktops>
    <number>5</number>
    <firstdesk>4</firstdesk>
    <names>
      <name>alpha</name>
      <name>beta</name>
      <name>gamma</name>
      <name>delta</name>
      <name>epsilon</name>
    </names>
  </desktops>
  <resize>
    <drawContents>yes</drawContents>
    <popupShow>Always</popupShow>
    <popupPosition>Center</popupPosition>
  </resize>
  <margins>
    <top>1</top>
    <bottom>2</bottom>
    <left>3</left>
    <right>4</right>
  </margins>
  <applications/>
  <menu>
    <file>/var/lib/openbox/debian-menu.xml</file>
    <hideDelay>0</hideDelay>
    <middle>no</middle>
    <submenuShowDelay>0</submenuShowDelay>
    <submenuHideDelay>0</submenuHideDelay>
    <showIcons>no</showIcons>
    <manageDesktops>yes</manageDesktops>
  </menu>
  <keyboard/>
  <mouse/>
</openbox_config>
XML

  timeout 20 xvfb-run -a bash -lc '
    set -euo pipefail

    openbox --debug --sm-disable --config-file /tmp/openbox/rc.xml >/tmp/openbox.log 2>&1 &
    openbox_pid=$!

    cleanup() {
      kill "$openbox_pid" 2>/dev/null || true
      wait "$openbox_pid" 2>/dev/null || true
    }

    trap cleanup EXIT

    for _ in $(seq 1 40); do
      if grep -F -- "Moving to desktop 4" /tmp/openbox.log >/dev/null 2>&1; then
        exit 0
      fi

      if ! kill -0 "$openbox_pid" 2>/dev/null; then
        wait "$openbox_pid"
      fi

      sleep 0.5
    done

    printf "openbox did not report the expected desktop from rc.xml\n" >&2
    exit 1
  '

  require_contains /tmp/openbox.log "Moving to desktop 4"
}

test_kdoctools() {
  log_step "kdoctools5"
  mkdir -p /tmp/kdoctools
  cat > /tmp/kdoctools/index.docbook <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<article xmlns="http://docbook.org/ns/docbook" version="5.0" xml:lang="en">
  <title>KDoc Smoke</title>
  <section xml:id="intro">
    <title>Intro</title>
    <para>Hello from DocBook.</para>
  </section>
</article>
XML

  meinproc5 --output /tmp/kdoctools/out.html /tmp/kdoctools/index.docbook >/tmp/kdoctools.stdout 2>/tmp/kdoctools.log
  require_nonempty_file /tmp/kdoctools/out.html
  require_contains /tmp/kdoctools/out.html "KDoc Smoke"
  require_contains /tmp/kdoctools/out.html "Hello from DocBook."
}

test_yelp_tools() {
  log_step "yelp-tools"
  mkdir -p /tmp/yelp-tools/help /tmp/yelp-tools/out
  cat > /tmp/yelp-tools/help/index.page <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<page xmlns="http://projectmallard.org/1.0/" type="guide" id="index">
  <info>
    <title type="text">Smoke Help</title>
  </info>
  <title>Smoke Help</title>
  <p>Testing Yelp tools with Mallard XML.</p>
</page>
XML

  (
    cd /tmp/yelp-tools/help
    yelp-check validate index.page
    yelp-build html -o /tmp/yelp-tools/out .
  ) >/tmp/yelp-tools.log 2>&1

  require_nonempty_file /tmp/yelp-tools/out/index.html
  require_contains /tmp/yelp-tools/out/index.html "Smoke Help"
}

test_llvm_toolchain() {
  log_step "llvm-toolchain-18"
  local llvm_binary=/tmp/llvm-src/build/bin/llvm-mt
  mkdir -p /tmp/llvm-src
  (
    cd /tmp/llvm-src
    apt-get update >/tmp/llvm-apt-update.log 2>&1
    apt-get source llvm-toolchain-18 >/tmp/llvm-source.log 2>&1
    src_dir="$(find . -maxdepth 1 -type d -name 'llvm-toolchain-18-*' | head -n1)"
    test -n "$src_dir"
    cmake \
      -S "$src_dir/llvm" \
      -B build \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_LIBXML2=FORCE_ON \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_INCLUDE_BENCHMARKS=OFF \
      -DLLVM_TARGETS_TO_BUILD=X86 \
      >/tmp/llvm-cmake.log 2>&1
    ninja -C build llvm-mt >/tmp/llvm-ninja.log 2>&1
    "$llvm_binary" \
      /manifest "$src_dir/llvm/test/tools/llvm-mt/Inputs/test_manifest.manifest" \
      /manifest "$src_dir/llvm/test/tools/llvm-mt/Inputs/additional.manifest" \
      /out:/tmp/merged.manifest \
      >/tmp/llvm-mt.log 2>&1
  )

  assert_binary_uses_expected_libxml "$llvm_binary" /tmp/llvm-ldd.log
  require_contains /tmp/merged.manifest '<assemblyIdentity program="displayDriver"/>'
  require_contains /tmp/merged.manifest '<supportedOS Id="FooOS"/>'
}

validate_dependents_inventory
if [[ "$PACKAGE_MODE" == "safe" ]]; then
  install_prebuilt_safe_packages
else
  build_original_libxml
fi
assert_selected_libxml_is_used
test_libvirt_daemon
test_postgresql
test_php_xml
test_python_lxml
test_xmlstarlet
test_mariadb_connect
test_cyrus_caldav
test_yelp
test_libobt
test_kdoctools
test_yelp_tools
test_llvm_toolchain

log_step "All dependent checks passed"
CONTAINER_SCRIPT
