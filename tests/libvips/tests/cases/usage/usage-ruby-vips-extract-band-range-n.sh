#!/usr/bin/env bash
# @testcase: usage-ruby-vips-extract-band-range-n
# @title: ruby-vips extract_band range with n parameter
# @description: Builds a four-band image with distinct per-band constants, calls Vips::Image#extract_band(1, n: 2) to pull two contiguous bands, and verifies the resulting image has exactly two bands and the correct middle-band values at every pixel.
# @timeout: 120
# @tags: usage, ruby, image, bands
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 2x2 image with four bands, per-band constants 10, 20, 30, 40.
data = []
4.times do
  data.concat([10, 20, 30, 40])
end
src = Vips::Image.new_from_memory(data.pack('C*'), 2, 2, 4, :uchar)
raise "src bands" unless src.bands == 4

# Pull bands 1 and 2 (values 20 and 30).
mid = src.extract_band(1, n: 2)
raise "mid bands #{mid.bands}" unless mid.bands == 2
raise "mid dims" unless mid.width == 2 && mid.height == 2

(0...2).each do |x|
  (0...2).each do |y|
    pt = mid.getpoint(x, y)
    raise "pt #{x},#{y} #{pt.inspect}" unless pt == [20.0, 30.0]
  end
end

out_path = File.join(tmpdir, "mid.tif")
mid.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)
puts "extract_band 1 n=2 bands=#{mid.bands}"
RUBY

[[ -s "$tmpdir/mid.tif" ]] || { echo "missing tif" >&2; exit 1; }
