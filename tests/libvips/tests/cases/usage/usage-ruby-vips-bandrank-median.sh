#!/usr/bin/env bash
# @testcase: usage-ruby-vips-bandrank-median
# @title: ruby-vips bandrank computes per-pixel median across images
# @description: Stacks three single-band images via Vips::Image#bandrank and verifies the per-pixel result equals the elementwise median of the inputs at multiple sample locations, including pixels where the median is the smallest, middle, or largest input.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Three 4x1 single-band images. Each column has the three input values
# (a, b, c) so the median is well-defined and the expected result is known.
a_pixels = [10, 30, 50, 90]
b_pixels = [20, 25, 40, 80]
c_pixels = [15, 35, 60, 85]

a = Vips::Image.new_from_memory(a_pixels.pack('C*'), 4, 1, 1, :uchar)
b = Vips::Image.new_from_memory(b_pixels.pack('C*'), 4, 1, 1, :uchar)
c = Vips::Image.new_from_memory(c_pixels.pack('C*'), 4, 1, 1, :uchar)
[a, b, c].each_with_index do |img, i|
  raise "input #{i} dims" unless img.width == 4 && img.height == 1 && img.bands == 1
end

# bandrank with index 1 (the middle of three) is the per-pixel median.
median = Vips::Image.bandrank([a, b, c], index: 1)
raise "median dims" unless median.width == 4 && median.height == 1
raise "median bands" unless median.bands == 1

expected = [a_pixels, b_pixels, c_pixels].transpose.map { |triple| triple.sort[1] }
raise "expected check" unless expected == [15, 30, 50, 85]

(0...4).each do |x|
  v = median.getpoint(x, 0)[0]
  raise "median(#{x})=#{v} want #{expected[x]}" unless v == expected[x].to_f
end

# bandrank with index 0 == elementwise minimum, index 2 == elementwise maximum.
mn = Vips::Image.bandrank([a, b, c], index: 0)
mx = Vips::Image.bandrank([a, b, c], index: 2)
(0...4).each do |x|
  triple = [a_pixels[x], b_pixels[x], c_pixels[x]]
  raise "min(#{x})" unless mn.getpoint(x, 0)[0] == triple.min.to_f
  raise "max(#{x})" unless mx.getpoint(x, 0)[0] == triple.max.to_f
end

puts "bandrank median=#{(0...4).map { |x| median.getpoint(x, 0)[0].to_i }.inspect}"
RUBY
