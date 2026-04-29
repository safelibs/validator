#!/usr/bin/env bash
# @testcase: usage-ruby-vips-bandjoin-image
# @title: ruby-vips bandjoin image
# @description: Uses ruby-vips to run libvips bandjoin image behavior.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "a=Vips::Image.black(4,4)+1; b=Vips::Image.black(4,4)+2; out=a.bandjoin(b); out.write_to_file(ARGV[0]); puts \"bands=#{out.bands}\"" "$tmpdir/out.png"
