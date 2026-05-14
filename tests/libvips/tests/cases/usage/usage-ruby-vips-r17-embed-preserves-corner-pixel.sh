#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-embed-preserves-corner-pixel
# @title: ruby-vips Image#embed at (0,0) keeps the original pixel at the (0,0) corner intact
# @description: Builds a 4x4 uchar image with the (0,0) pixel set to 200 via draw_rect!, embeds the image into an 8x8 canvas at offset (0,0) with extend :black, and asserts getpoint(0,0)[0] equals 200 — confirming libvips' embed places the input at the specified origin without modification.
# @timeout: 60
# @tags: usage, vips, ruby, embed, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
base = (Vips::Image.black(4, 4) + 10).cast(:uchar)
src = base.mutate { |m| m.draw_rect!([200], 0, 0, 1, 1, fill: true) }
raise "src(0,0)=#{src.getpoint(0, 0)}" unless src.getpoint(0, 0) == [200.0]

out = src.embed(0, 0, 8, 8, extend: :black)
raise "out dims=#{out.width}x#{out.height}" unless out.width == 8 && out.height == 8
raise "out(0,0)=#{out.getpoint(0, 0)}" unless out.getpoint(0, 0) == [200.0]
puts "embed corner ok"
RUBY
