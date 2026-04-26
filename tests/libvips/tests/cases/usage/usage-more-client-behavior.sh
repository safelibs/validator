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

def pixel_values(image, x, y)
  image.extract_area(x, y, 1, 1).write_to_memory.bytes
end

def gray_pixel(image, x, y)
  pixel_values(image, x, y)[0]
end

def assert_close_rgb(image, x, y, expected)
  actual = pixel_values(image, x, y)
  unless actual.zip(expected).all? { |value, want| (value - want).abs <= 1 }
    raise "unexpected rgb #{actual.inspect} != #{expected.inspect}"
  end
end

case case_id
when "usage-ruby-vips-fliphor-sample"
  image = gray_image(2, 1, [10, 200])
  out = image.fliphor
  raise "fliphor mismatch" unless gray_pixel(out, 0, 0) == 200 && gray_pixel(out, 1, 0) == 10
  puts "fliphor #{gray_pixel(out, 0, 0)} #{gray_pixel(out, 1, 0)}"
when "usage-ruby-vips-flipver-sample"
  image = gray_image(1, 2, [10, 200])
  out = image.flipver
  raise "flipver mismatch" unless gray_pixel(out, 0, 0) == 200 && gray_pixel(out, 0, 1) == 10
  puts "flipver #{gray_pixel(out, 0, 0)} #{gray_pixel(out, 0, 1)}"
when "usage-ruby-vips-rot180-sample"
  image = gray_image(2, 2, [10, 20, 30, 40])
  out = image.rot180
  expected = [40, 30, 20, 10]
  actual = [
    gray_pixel(out, 0, 0),
    gray_pixel(out, 1, 0),
    gray_pixel(out, 0, 1),
    gray_pixel(out, 1, 1),
  ]
  raise "rot180 mismatch #{actual.inspect}" unless actual == expected
  puts "rot180 #{actual.join(',')}"
when "usage-ruby-vips-insert-generated"
  base = gray_image(6, 6, Array.new(36, 10))
  patch = gray_image(2, 2, Array.new(4, 200))
  out = base.insert(patch, 2, 2)
  raise "insert mismatch" unless gray_pixel(out, 1, 1) == 10 && gray_pixel(out, 2, 2) == 200 && gray_pixel(out, 3, 3) == 200
  puts "insert #{gray_pixel(out, 1, 1)} #{gray_pixel(out, 2, 2)}"
when "usage-ruby-vips-read-buffer-png"
  image = gray_image(2, 2, [5, 15, 25, 35])
  data = image.write_to_buffer(".png")
  reload = Vips::Image.new_from_buffer(data, "")
  actual = [
    gray_pixel(reload, 0, 0),
    gray_pixel(reload, 1, 0),
    gray_pixel(reload, 0, 1),
    gray_pixel(reload, 1, 1),
  ]
  raise "buffer roundtrip mismatch #{actual.inspect}" unless actual == [5, 15, 25, 35]
  puts "buffer #{actual.join(',')}"
when "usage-ruby-vips-extract-area-generated"
  image = gray_image(4, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
  out = image.extract_area(1, 1, 2, 2)
  actual = [
    gray_pixel(out, 0, 0),
    gray_pixel(out, 1, 0),
    gray_pixel(out, 0, 1),
    gray_pixel(out, 1, 1),
  ]
  raise "extract mismatch #{actual.inspect}" unless actual == [6, 7, 10, 11]
  puts "extract #{actual.join(',')}"
when "usage-ruby-vips-bandmean-generated"
  image = multiband_image(1, 1, 3, [12, 24, 36])
  out = image.bandmean
  raise "bandmean mismatch" unless (out.avg - 24.0).abs < 0.01
  puts "bandmean #{out.avg}"
when "usage-ruby-vips-embed-generated"
  image = gray_image(2, 1, [50, 60])
  out = image.embed(1, 2, 6, 5)
  raise "embed mismatch" unless gray_pixel(out, 0, 0) == 0 && gray_pixel(out, 1, 2) == 50 && gray_pixel(out, 2, 2) == 60
  puts "embed #{gray_pixel(out, 0, 0)} #{gray_pixel(out, 1, 2)} #{gray_pixel(out, 2, 2)}"
when "usage-ruby-vips-flatten-background"
  image = multiband_image(1, 1, 4, [10, 20, 30, 128])
  out = image.flatten(background: [255, 255, 255])
  assert_close_rgb(out, 0, 0, [132, 137, 142])
  puts "flatten #{pixel_values(out, 0, 0).join(',')}"
when "usage-ruby-vips-png-file-output"
  image = gray_image(2, 2, [90, 100, 110, 120])
  path = File.join(tmpdir, "out.png")
  image.write_to_file(path)
  reload = Vips::Image.new_from_file(path)
  actual = [
    gray_pixel(reload, 0, 0),
    gray_pixel(reload, 1, 0),
    gray_pixel(reload, 0, 1),
    gray_pixel(reload, 1, 1),
  ]
  raise "png reload mismatch #{actual.inspect}" unless actual == [90, 100, 110, 120]
  puts "png #{actual.join(',')}"
else
  raise "unknown libvips additional usage case: #{case_id}"
end
RUBY
