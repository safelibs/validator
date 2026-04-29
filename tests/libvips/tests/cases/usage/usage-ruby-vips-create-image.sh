#!/usr/bin/env bash
# @testcase: usage-ruby-vips-create-image
# @title: ruby-vips create image
# @description: Uses ruby-vips to run libvips create image behavior.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(16,12,bands:3); image.write_to_file(ARGV[0]); puts \"size=#{image.width}x#{image.height}\"" "$tmpdir/out.png"
