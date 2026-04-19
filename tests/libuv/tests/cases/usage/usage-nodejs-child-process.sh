#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "require('child_process').execFile('/bin/echo',['child-ok'],(e,out)=>{if(e)throw e; console.log(out.trim());});" "$tmpdir/node.txt"