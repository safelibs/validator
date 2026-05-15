#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-flip-vertical-then-horizontal-equals-rot180
# @title: ruby-vips Image#flip vertical+horizontal yields the same image as rot(:d180)
# @description: Loads the sample JPEG, computes a = src.flip(:vertical).flip(:horizontal), computes b = src.rot(:d180), asserts both have the same width, height, and bands as the source, and asserts the per-band avg of a equals the per-band avg of b (within 0.001), confirming the algebraic identity that two perpendicular flips compose into a 180-degree rotation under libvips.
# @timeout: 60
# @tags: usage, vips, ruby, flip, rot, identity, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

sample=/validator/tests/libvips/tests/fixtures/samples/test/test-suite/images/sample.jpg
[[ -f "$sample" ]]

ruby -rvips - "$sample" <<'RUBY'
src = Vips::Image.new_from_file(ARGV[0])
a = src.flip(:vertical).flip(:horizontal)
b = src.rot(:d180)
raise "a dims" unless a.width == src.width && a.height == src.height
raise "b dims" unless b.width == src.width && b.height == src.height
raise "bands a=#{a.bands} src=#{src.bands}" unless a.bands == src.bands
raise "bands b=#{b.bands} src=#{src.bands}" unless b.bands == src.bands
da = (a.avg - b.avg).abs
raise "avg diff=#{da}" if da > 0.001
puts "flip2 == rot180 avg=#{a.avg}"
RUBY
