#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

def bytes(image)
  image.cast(:uchar).write_to_memory.bytes
end

case case_id
when "usage-ruby-vips-black-dimensions-batch11"
  image = Vips::Image.black(3, 2)
  raise "black dimensions" unless image.width == 3 && image.height == 2
  puts "black #{image.width}x#{image.height}"
when "usage-ruby-vips-xyz-bands-batch11"
  image = Vips::Image.xyz(3, 2)
  raise "xyz bands" unless image.bands == 2 && image.width == 3 && image.height == 2
  puts "xyz #{image.bands}"
when "usage-ruby-vips-linear-offset-batch11"
  image = gray_image(2, 1, [4, 8])
  out = image.linear(3, 2).cast(:uchar)
  raise "linear mismatch" unless bytes(out) == [14, 26]
  puts "linear #{bytes(out).join(',')}"
when "usage-ruby-vips-memory-png-roundtrip-batch11"
  image = gray_image(2, 2, [1, 2, 3, 4])
  data = image.write_to_buffer(".png")
  reload = Vips::Image.new_from_buffer(data, "")
  raise "png memory" unless bytes(reload) == [1, 2, 3, 4]
  puts "png #{data.bytesize}"
when "usage-ruby-vips-memory-ppm-roundtrip-batch11"
  image = multiband_image(1, 2, 3, [10, 20, 30, 40, 50, 60])
  data = image.write_to_buffer(".ppm")
  reload = Vips::Image.new_from_buffer(data, "")
  raise "ppm memory" unless bytes(reload) == [10, 20, 30, 40, 50, 60]
  puts "ppm #{data.bytesize}"
when "usage-ruby-vips-insert-corner-batch11"
  base = gray_image(4, 4, Array.new(16, 10))
  patch = gray_image(1, 1, [200])
  out = base.insert(patch, 3, 3)
  raise "insert corner" unless bytes(out.extract_area(3, 3, 1, 1)) == [200]
  puts "insert"
when "usage-ruby-vips-embed-background-batch11"
  image = gray_image(1, 1, [70])
  out = image.embed(1, 1, 3, 3, background: [9])
  values = bytes(out)
  raise "embed background" unless values[0] == 9 && values[4] == 70
  puts "embed #{values.join(',')}"
when "usage-ruby-vips-bandmean-rgb-batch11"
  image = multiband_image(1, 1, 3, [30, 60, 90])
  out = image.bandmean
  raise "bandmean" unless (out.avg - 60.0).abs < 0.01
  puts "bandmean #{out.avg}"
when "usage-ruby-vips-flatten-white-batch11"
  image = multiband_image(1, 1, 4, [0, 0, 0, 128])
  out = image.flatten(background: [255, 255, 255])
  raise "flatten" unless bytes(out)[0] > 100
  puts "flatten #{bytes(out).join(',')}"
when "usage-ruby-vips-extract-corner-batch11"
  image = gray_image(3, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9])
  out = image.extract_area(1, 1, 2, 2)
  raise "extract" unless bytes(out) == [5, 6, 8, 9]
  puts "extract #{bytes(out).join(',')}"
else
  raise "unknown libvips eleventh-batch usage case: #{case_id}"
end
RUBY
