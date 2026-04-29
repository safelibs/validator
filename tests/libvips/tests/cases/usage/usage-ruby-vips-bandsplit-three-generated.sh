#!/usr/bin/env bash
# @testcase: usage-ruby-vips-bandsplit-three-generated
# @title: ruby-vips generated bandsplit three
# @description: Calls bandsplit on a generated three-band image with ruby-vips and verifies it returns three single-band images with the original per-channel values.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-bandsplit-three-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).cast(:uchar).write_to_memory.bytes[0]
end

image = multiband_image(1, 1, 3, [11, 22, 33])
bands = image.bandsplit
raise "split count mismatch" unless bands.length == 3
raise "split values mismatch" unless bands.map { |b| b.write_to_memory.bytes[0] } == [11, 22, 33]
puts "split #{bands.length}"
RUBY
