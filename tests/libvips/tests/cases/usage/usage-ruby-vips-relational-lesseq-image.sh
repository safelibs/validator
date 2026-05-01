#!/usr/bin/env bash
# @testcase: usage-ruby-vips-relational-lesseq-image
# @title: ruby-vips relational lesseq between two images
# @description: Compares two single-band images via Vips::Image#relational(:lesseq) and verifies the output is 255 where the left input is less than or equal to the right input and 0 elsewhere across every sample position.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

a_pixels = [10, 20, 30, 40, 50]
b_pixels = [15, 20, 25, 50, 49]
expected = a_pixels.zip(b_pixels).map { |a, b| a <= b ? 255 : 0 }

a = Vips::Image.new_from_memory(a_pixels.pack('C*'), 5, 1, 1, :uchar)
b = Vips::Image.new_from_memory(b_pixels.pack('C*'), 5, 1, 1, :uchar)

result = a.relational(b, :lesseq)
raise "dims" unless result.width == 5 && result.height == 1
raise "bands" unless result.bands == 1

(0...5).each do |x|
  v = result.getpoint(x, 0)[0]
  raise "(#{x}) lesseq=#{v} want #{expected[x]}" unless v == expected[x].to_f
end

# moreeq is the swap: b lesseq a == a moreeq b.
swap = a.relational(b, :moreeq)
expected_swap = a_pixels.zip(b_pixels).map { |a, b| a >= b ? 255 : 0 }
(0...5).each do |x|
  v = swap.getpoint(x, 0)[0]
  raise "(#{x}) moreeq=#{v} want #{expected_swap[x]}" unless v == expected_swap[x].to_f
end

puts "relational lesseq/moreeq ok"
RUBY
