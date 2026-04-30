#!/usr/bin/env bash
# @testcase: usage-ruby-vips-stats-per-band
# @title: ruby-vips stats per-band statistics
# @description: Builds a small multi-band image with known per-band ranges and verifies that Vips::Image#stats returns a matrix whose first row carries the global min/max and whose subsequent rows carry the expected per-band min and max.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 2x2 image with three bands. Each band has a known [min, max] range.
# Layout: pixels are interleaved (b0, b1, b2) per pixel, in row-major order.
# Band 0 values: 1, 4, 7, 10  -> min=1, max=10
# Band 1 values: 2, 5, 8, 11  -> min=2, max=11
# Band 2 values: 3, 6, 9, 12  -> min=3, max=12
data = [
  1, 2, 3,    4, 5, 6,
  7, 8, 9,    10, 11, 12,
]
src = Vips::Image.new_from_memory(data.pack('C*'), 2, 2, 3, :uchar)
raise "src bands" unless src.bands == 3

stats = src.stats
# stats matrix is shape [width=10, height=bands+1] in current libvips:
# column 0 = min, column 1 = max, then xpos/ypos/sum/sum2/mean/sigma/...
# Row 0 holds the combined statistics; rows 1..bands hold per-band stats.
raise "stats dims #{stats.width}x#{stats.height}" unless stats.width >= 6 && stats.height == 4

# Column 0: minimum, column 1: maximum.
# Row 0: combined across all bands; rows 1..bands: per-band stats.
combined_min = stats.getpoint(0, 0).first
combined_max = stats.getpoint(1, 0).first
raise "combined min #{combined_min}" unless combined_min == 1.0
raise "combined max #{combined_max}" unless combined_max == 12.0

expected = [[1.0, 10.0], [2.0, 11.0], [3.0, 12.0]]
expected.each_with_index do |(emin, emax), idx|
  row = idx + 1
  got_min = stats.getpoint(0, row).first
  got_max = stats.getpoint(1, row).first
  raise "band #{idx} min #{got_min} (want #{emin})" unless got_min == emin
  raise "band #{idx} max #{got_max} (want #{emax})" unless got_max == emax
end

puts "stats combined=[#{combined_min},#{combined_max}] bands=#{src.bands}"
RUBY
