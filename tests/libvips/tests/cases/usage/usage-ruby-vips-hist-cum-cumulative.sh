#!/usr/bin/env bash
# @testcase: usage-ruby-vips-hist-cum-cumulative
# @title: ruby-vips hist_cum produces cumulative histogram
# @description: Computes the histogram of a small grayscale image with hist_find and applies hist_cum, verifying the cumulative histogram is monotonically non-decreasing across all 256 bins and that the final bin equals the total pixel count.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Build an image with a known mix of grey levels so the cumulative
# histogram has predictable behavior.
width = 8
height = 8
total = width * height
half = total / 2
pixels = Array.new(half, 10) + Array.new(total - half, 200)
src = Vips::Image.new_from_memory(pixels.pack('C*'), width, height, 1, :uchar)

hist = src.hist_find
raise "hist dims" unless hist.width == 256 && hist.height == 1 && hist.bands == 1

cum = hist.hist_cum
raise "cum dims" unless cum.width == 256 && cum.height == 1 && cum.bands == 1

# Read every bin and check monotonicity.
prev = 0.0
last = 0.0
(0...256).each do |i|
  v = cum.getpoint(i, 0)[0]
  raise "non-monotonic at #{i}: #{v} < #{prev}" if v < prev
  prev = v
  last = v
end

raise "final bin #{last} != total #{total}" unless last == total.to_f
raise "bin 9 should be 0 #{cum.getpoint(9, 0)}" unless cum.getpoint(9, 0)[0] == 0.0
raise "bin 10 should be #{half} got #{cum.getpoint(10, 0)}" unless cum.getpoint(10, 0)[0] == half.to_f
raise "bin 199 should still be #{half}" unless cum.getpoint(199, 0)[0] == half.to_f
raise "bin 200 should be #{total}" unless cum.getpoint(200, 0)[0] == total.to_f

puts "hist_cum monotonic last=#{last}"
RUBY
