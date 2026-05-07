#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-os-endianness-arch-platform
# @title: Node.js os.endianness, os.arch, and os.platform expose well-formed identifiers
# @description: Calls os.endianness, os.arch, and os.platform and asserts endianness is 'BE' or 'LE', platform equals 'linux' on Ubuntu 24.04, and arch is one of the known Node.js architecture strings.
# @timeout: 60
# @tags: usage, os, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const os = require('os');
const e = os.endianness();
assert.ok(e === 'BE' || e === 'LE', e);
assert.strictEqual(os.platform(), 'linux');
const a = os.arch();
assert.ok(['x64','arm64','arm','ia32','ppc64','s390x','riscv64','mips','mipsel'].includes(a), a);
console.log('OK os.identity');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK os.identity'
