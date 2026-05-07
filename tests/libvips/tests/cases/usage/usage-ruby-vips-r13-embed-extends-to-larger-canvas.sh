#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-embed-extends-to-larger-canvas
# @title: ruby-vips Image#embed places a 4x4 image into a 10x10 canvas at offset (3,3)
# @description: Builds a 4x4 single-band uchar image of constant 200 and verifies embed(3, 3, 10, 10) returns an image with width == 10 and height == 10, asserting libvips' embed produces the expected canvas dimensions when extending with the default background.
# @timeout: 60
# @tags: usage, vips, ruby, embed
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(4, 4) + 200).cast(:uchar)
out = img.embed(3, 3, 10, 10)
raise "embed dims=#{out.width}x#{out.height}" unless out.width == 10 && out.height == 10
puts "embed dims=#{out.width}x#{out.height}"
RUBY
