#!/usr/bin/env bash
# @testcase: usage-ruby-vips-join-vertical-generated
# @title: ruby-vips generated vertical join
# @description: Joins two generated images vertically with ruby-vips and verifies the stacked pixel payload and output dimensions.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-join-vertical-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" <<'RUBY'
case_id = ARGV[0]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).cast(:uchar).write_to_memory.bytes[0]
end

top = gray_image(2, 1, [10, 20])
bottom = gray_image(2, 1, [30, 40])
out = top.join(bottom, :vertical)
raise 'join vertical mismatch' unless out.width == 2 && out.height == 2
raise 'join vertical payload mismatch' unless out.write_to_memory.bytes == [10, 20, 30, 40]
puts "#{out.width}x#{out.height}"
RUBY
