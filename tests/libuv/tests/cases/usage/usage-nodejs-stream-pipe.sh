#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "const {Readable}=require('stream'); Readable.from(['stream-ok']).on('data',d=>console.log(d.toString()));" "$tmpdir/node.txt"