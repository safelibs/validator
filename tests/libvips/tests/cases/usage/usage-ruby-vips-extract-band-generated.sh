#!/usr/bin/env bash
# @testcase: usage-ruby-vips-extract-band-generated
# @title: ruby-vips generated extract band
# @description: Extracts a selected band from a generated multiband image with ruby-vips and verifies the resulting grayscale payload.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-extract-band-generated"
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

image = multiband_image(2, 1, 3, [10, 20, 30, 40, 50, 60])
out = image.extract_band(1)
raise 'extract band mismatch' unless out.write_to_memory.bytes == [20, 50]
puts out.width
RUBY
