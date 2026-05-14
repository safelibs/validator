#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-flip-vertical-double-restores-identity
# @title: ruby-vips Image#flip(:vertical) applied twice restores the original avg/min/max
# @description: Builds a 12x6 uchar image with a constant value 70, flips vertically with flip(:vertical) twice, and asserts the result has identical width/height/bands and identical avg/min/max statistics to the input, confirming libvips' vertical flip is a self-inverse operation.
# @timeout: 60
# @tags: usage, vips, ruby, flip, identity, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(12, 6) + 70).cast(:uchar)
out = src.flip(:vertical).flip(:vertical)
raise "dims #{out.width}x#{out.height}" unless out.width == src.width && out.height == src.height
raise "bands=#{out.bands}" unless out.bands == src.bands
raise "avg mismatch #{out.avg} vs #{src.avg}" unless out.avg == src.avg
raise "min mismatch" unless out.min == src.min
raise "max mismatch" unless out.max == src.max
puts "flip-vert*2 identity"
RUBY
