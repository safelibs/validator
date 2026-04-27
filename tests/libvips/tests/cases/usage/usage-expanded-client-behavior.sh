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
when 'usage-ruby-vips-flip-horizontal-generated'
  image = gray_image(3, 1, [10, 20, 30])
  out = image.flip(:horizontal)
  raise 'flip horizontal mismatch' unless out.write_to_memory.bytes == [30, 20, 10]
  puts out.width
when 'usage-ruby-vips-flip-vertical-generated'
  image = gray_image(1, 3, [10, 20, 30])
  out = image.flip(:vertical)
  raise 'flip vertical mismatch' unless out.write_to_memory.bytes == [30, 20, 10]
  puts out.height
when 'usage-ruby-vips-rot90-generated'
  image = gray_image(2, 1, [10, 20])
  out = image.rot90
  raise 'rot90 mismatch' unless out.width == 1 && out.height == 2
  puts "#{out.width}x#{out.height}"
when 'usage-ruby-vips-embed-generated'
  image = gray_image(2, 1, [10, 20])
  out = image.embed(1, 1, 4, 3, extend: :copy)
  raise 'embed mismatch' unless out.width == 4 && out.height == 3
  puts "#{out.width}x#{out.height}"
when 'usage-ruby-vips-extract-area-generated'
  image = gray_image(3, 2, [1, 2, 3, 4, 5, 6])
  out = image.extract_area(1, 0, 1, 2)
  raise 'extract area mismatch' unless out.write_to_memory.bytes == [2, 5]
  puts out.height
when 'usage-ruby-vips-bandmean-generated'
  image = multiband_image(2, 1, 3, [10, 20, 30, 40, 50, 60])
  out = image.bandmean.cast(:uchar)
  raise 'bandmean mismatch' unless out.write_to_memory.bytes == [20, 50]
  puts out.width
when 'usage-ruby-vips-extract-band-generated'
  image = multiband_image(2, 1, 3, [10, 20, 30, 40, 50, 60])
  out = image.extract_band(1)
  raise 'extract band mismatch' unless out.write_to_memory.bytes == [20, 50]
  puts out.width
when 'usage-ruby-vips-subtract-constant-generated'
  image = gray_image(2, 1, [20, 30])
  out = (image - 5).cast(:uchar)
  raise 'subtract mismatch' unless out.write_to_memory.bytes == [15, 25]
  puts out.write_to_memory.bytes.last
when 'usage-ruby-vips-divide-constant-generated'
  image = gray_image(2, 1, [20, 40])
  out = (image / 2).cast(:uchar)
  raise 'divide mismatch' unless out.write_to_memory.bytes == [10, 20]
  puts out.write_to_memory.bytes.last
when 'usage-ruby-vips-avg-generated'
  image = gray_image(2, 2, [10, 20, 30, 40])
  raise 'avg mismatch' unless image.avg == 25
  puts image.avg
else
  raise "unknown libvips expanded usage case: #{case_id}"
end
RUBY
