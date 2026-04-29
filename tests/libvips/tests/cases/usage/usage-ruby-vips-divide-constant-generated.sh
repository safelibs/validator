#!/usr/bin/env bash
# @testcase: usage-ruby-vips-divide-constant-generated
# @title: ruby-vips generated divide constant
# @description: Divides a generated image by a scalar constant with ruby-vips and verifies the resulting pixel values.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-divide-constant-generated"
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

image = gray_image(2, 1, [20, 40])
out = (image / 2).cast(:uchar)
raise 'divide mismatch' unless out.write_to_memory.bytes == [10, 20]
puts out.write_to_memory.bytes.last
RUBY
