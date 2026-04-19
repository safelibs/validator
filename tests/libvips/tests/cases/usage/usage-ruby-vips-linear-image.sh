#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(4,4)+10; out=image.linear(2,1); puts \"avg=#{out.avg}\"" "$tmpdir/out.png"