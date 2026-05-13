#!/usr/bin/env bash
# @testcase: usage-curl-r16-resolve-maps-fake-host
# @title: curl --resolve routes a fake hostname to the loopback http.server
# @description: Hosts content on 127.0.0.1 and asserts curl --resolve fake.r16.example:port:127.0.0.1 plus a URL using that hostname returns the loopback body, locking in --resolve's pre-DNS rewrite without depending on /etc/hosts.
# @timeout: 60
# @tags: usage, curl, resolve, dns
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
pid=""
cleanup() {
    if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
    rm -rf "$tmpdir"
}
trap cleanup EXIT

mkdir -p "$tmpdir/srv"
printf 'r16 resolve-fake-host body\n' >"$tmpdir/srv/index.txt"
port=$((23600 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 \
    --resolve "fake.r16.example:$port:127.0.0.1" \
    "http://fake.r16.example:$port/index.txt" -o "$tmpdir/got.txt"

validator_assert_contains "$tmpdir/got.txt" 'r16 resolve-fake-host body'
