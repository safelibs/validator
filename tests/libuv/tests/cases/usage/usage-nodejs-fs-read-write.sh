#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "const fs=require('fs'); fs.writeFileSync(process.argv[1],'payload'); console.log(fs.readFileSync(process.argv[1],'utf8'));" "$tmpdir/node.txt"