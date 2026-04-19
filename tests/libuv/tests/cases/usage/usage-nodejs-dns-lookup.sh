#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "require('dns').lookup('localhost',(e,a)=>{if(e)throw e; console.log('address='+a);});" "$tmpdir/node.txt"