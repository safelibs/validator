#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-shrinkh-horizontal
# @title: ruby-vips shrinkh horizontal-only block reduction
# @description: Calls Vips::Image#shrinkh on a 4x1 row to reduce horizontally by a factor of 2 and verifies the two output samples equal the block means of the input.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

pixels = [10, 20, 200, 220]
img = Vips::Image.new_from_memory(pixels.pack('C*'), 4, 1, 1, :uchar)

out = img.shrinkh(2)
raise "dims #{out.width}x#{out.height}" unless out.width == 2 && out.height == 1
raise "bands" unless out.bands == 1

samples = (0...2).map { |x| out.getpoint(x, 0)[0] }
expected = [(10 + 20) / 2.0, (200 + 220) / 2.0]
samples.zip(expected).each_with_index do |(got, want), idx|
  raise "shrinkh[#{idx}] got=#{got} want=#{want}" unless (got - want).abs < 1.0
end

puts "shrinkh horizontal block-mean ok #{samples.join(',')}"
RUBY
