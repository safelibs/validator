#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-mapim-identity-warp
# @title: ruby-vips mapim identity warp returns the input
# @description: Builds a two-band index image equal to (x, y) and verifies Vips::Image#mapim warps a 3x3 source through the identity coordinate map back to the original pixels.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

src_pixels = [10, 20, 30, 40, 50, 60, 70, 80, 90]
src = Vips::Image.new_from_memory(src_pixels.pack('C*'), 3, 3, 1, :uchar)

# Identity coord map: at (x, y) the index is (x, y), so mapim returns src.
xs = [0, 1, 2, 0, 1, 2, 0, 1, 2]
ys = [0, 0, 0, 1, 1, 1, 2, 2, 2]
xi = Vips::Image.new_from_memory(xs.pack('s<*'), 3, 3, 1, :short)
yi = Vips::Image.new_from_memory(ys.pack('s<*'), 3, 3, 1, :short)
index = xi.bandjoin(yi)
raise "index bands" unless index.bands == 2

warped = src.mapim(index)
raise "warped dims" unless warped.width == 3 && warped.height == 3

(0...3).each do |y|
  (0...3).each do |x|
    got = warped.getpoint(x, y)[0]
    want = src.getpoint(x, y)[0]
    raise "mapim(#{x},#{y}) got=#{got} want=#{want}" unless (got - want).abs < 0.5
  end
end

puts "mapim identity warp ok"
RUBY
