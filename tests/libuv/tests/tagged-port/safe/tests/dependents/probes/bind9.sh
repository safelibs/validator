#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing BIND 9"
  (
    set -euo pipefail
    local dir
    dir="$(mktemp -d /tmp/bind-test.XXXXXX)"
    cat >"${dir}/named.conf" <<'CFG'
options {
  directory "__DIR__";
  listen-on port 5300 { 127.0.0.1; };
  pid-file "__DIR__/named.pid";
  recursion no;
  allow-query { any; };
  dnssec-validation no;
};
zone "example.test" IN {
  type master;
  file "__DIR__/db.example.test";
};
CFG
    sed -i "s#__DIR__#${dir}#g" "${dir}/named.conf"
    cat >"${dir}/db.example.test" <<'ZONE'
$TTL 300
@ IN SOA ns1.example.test. hostmaster.example.test. 1 300 300 300 300
@ IN NS ns1.example.test.
ns1 IN A 127.0.0.1
www IN A 127.0.0.42
ZONE
    named-checkconf "${dir}/named.conf"
    /usr/sbin/named -g -c "${dir}/named.conf" >"${dir}/named.log" 2>&1 &
    pid=$!
    trap 'kill "${pid}" 2>/dev/null || true; wait "${pid}" 2>/dev/null || true' EXIT
    for _ in $(seq 1 50); do
      if dig +short @127.0.0.1 -p 5300 www.example.test A >"${dir}/dig.out" 2>/dev/null && \
         grep -qx '127.0.0.42' "${dir}/dig.out"; then
        exit 0
      fi
      sleep 0.2
    done
    cat "${dir}/named.log"
    exit 1
  )
}

main "$@"
