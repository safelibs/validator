#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(32,24,bands:3); out=image.resize(0.5); out.write_to_file(ARGV[0]); puts \"size=#{out.width}x#{out.height}\"" "$tmpdir/out.png"