#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case case_id
when 'usage-ruby-vips-rot90-generated'
  image = gray_image(2, 3, [1, 2, 3, 4, 5, 6])
  out = image.rot90
  raise 'bad size' unless out.width == 3 && out.height == 2
  puts "rot90 #{out.width}x#{out.height}"
when 'usage-ruby-vips-zoom-generated'
  image = gray_image(2, 2, [10, 20, 30, 40])
  out = image.zoom(2, 3)
  raise 'zoom mismatch' unless out.width == 4 && out.height == 6
  puts "zoom #{out.width}x#{out.height}"
when 'usage-ruby-vips-subsample-generated'
  image = gray_image(4, 4, Array.new(16, 90))
  out = image.subsample(2, 2)
  raise 'subsample mismatch' unless out.width == 2 && out.height == 2
  puts "subsample #{out.width}x#{out.height}"
when 'usage-ruby-vips-bandsplit-generated'
  image = multiband_image(2, 1, 3, [10, 20, 30, 40, 50, 60])
  parts = image.bandsplit
  raise 'bandsplit mismatch' unless parts.length == 3 && gray_pixel(parts[1], 1, 0) == 50
  puts "bandsplit #{parts.length}"
when 'usage-ruby-vips-max-generated'
  image = gray_image(2, 2, [10, 20, 30, 40])
  raise 'max mismatch' unless image.max == 40
  puts "max #{image.max}"
when 'usage-ruby-vips-min-generated'
  image = gray_image(2, 2, [10, 20, 30, 40])
  raise 'min mismatch' unless image.min == 10
  puts "min #{image.min}"
when 'usage-ruby-vips-add-constant-generated'
  image = gray_image(2, 1, [5, 15])
  out = (image + 5).cast(:uchar)
  raise 'add mismatch' unless gray_pixel(out, 0, 0) == 10 && gray_pixel(out, 1, 0) == 20
  puts "add #{gray_pixel(out, 1, 0)}"
when 'usage-ruby-vips-multiply-constant-generated'
  image = gray_image(2, 1, [5, 15])
  out = (image * 2).cast(:uchar)
  raise 'multiply mismatch' unless gray_pixel(out, 0, 0) == 10 && gray_pixel(out, 1, 0) == 30
  puts "multiply #{gray_pixel(out, 1, 0)}"
when 'usage-ruby-vips-write-memory-generated'
  image = gray_image(2, 2, [1, 2, 3, 4])
  bytes = image.write_to_memory.bytes
  raise 'memory mismatch' unless bytes.length == 4
  puts "memory #{bytes.length}"
when 'usage-ruby-vips-bandjoin-array-generated'
  image = gray_image(1, 1, [12])
  out = image.bandjoin([30, 200])
  raise 'bandjoin array mismatch' unless out.bands == 3
  puts "bands #{out.bands}"
else
  raise "unknown libvips further usage case: #{case_id}"
end
RUBY
