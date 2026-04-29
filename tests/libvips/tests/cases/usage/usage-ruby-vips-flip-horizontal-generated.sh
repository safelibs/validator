#!/usr/bin/env bash
# @testcase: usage-ruby-vips-flip-horizontal-generated
# @title: ruby-vips generated flip horizontal
# @description: Flips a generated image horizontally with ruby-vips and verifies the reversed pixel order.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-flip-horizontal-generated"
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

image = gray_image(3, 1, [10, 20, 30])
out = image.flip(:horizontal)
raise 'flip horizontal mismatch' unless out.write_to_memory.bytes == [30, 20, 10]
puts out.width
RUBY
