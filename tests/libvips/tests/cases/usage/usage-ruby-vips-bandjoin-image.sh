#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "a=Vips::Image.black(4,4)+1; b=Vips::Image.black(4,4)+2; out=a.bandjoin(b); out.write_to_file(ARGV[0]); puts \"bands=#{out.bands}\"" "$tmpdir/out.png"