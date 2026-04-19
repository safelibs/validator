#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(6,6,bands:3)+128; image.write_to_file(ARGV[0]); puts File.size(ARGV[0])" "$tmpdir/out.png"