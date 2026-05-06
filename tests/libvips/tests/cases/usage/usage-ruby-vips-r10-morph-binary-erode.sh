#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-morph-binary-erode
# @title: ruby-vips morph binary erode shrinks foreground square
# @description: Constructs a 5x5 binary image with a 3x3 foreground square and applies Vips::Image#morph with an erode 3x3 cross mask, verifying the foreground collapses to the centre pixel only.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

pixels = [
  0,   0,   0,   0,   0,
  0, 255, 255, 255,   0,
  0, 255, 255, 255,   0,
  0, 255, 255, 255,   0,
  0,   0,   0,   0,   0,
]
img = Vips::Image.new_from_memory(pixels.pack('C*'), 5, 5, 1, :uchar)

cross = Vips::Image.new_from_array(
  [
    [0, 255, 0],
    [255, 255, 255],
    [0, 255, 0],
  ],
  1,
)

eroded = img.morph(cross, :erode)
raise "dims" unless eroded.width == 5 && eroded.height == 5

(0...5).each do |y|
  (0...5).each do |x|
    got = eroded.getpoint(x, y)[0]
    want = (x == 2 && y == 2) ? 255 : 0
    raise "erode(#{x},#{y}) got=#{got} want=#{want}" unless got == want
  end
end

puts "morph erode collapses 3x3 to centre pixel"
RUBY
