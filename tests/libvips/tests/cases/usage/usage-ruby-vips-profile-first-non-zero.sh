#!/usr/bin/env bash
# @testcase: usage-ruby-vips-profile-first-non-zero
# @title: ruby-vips profile reports first non-zero pixel positions
# @description: Builds a synthetic image with a single off-axis bright pixel and uses Vips::Image#profile to obtain the per-row/per-column index of the first non-zero pixel, verifying both the column and row profiles match the expected coordinates.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 8x6 single-band image, all zeros except a single non-zero pixel at (5, 3).
width = 8
height = 6
target_x = 5
target_y = 3
rows = Array.new(height) do |y|
  Array.new(width) do |x|
    (x == target_x && y == target_y) ? 200 : 0
  end
end
src = Vips::Image.new_from_array(rows).cast(:uchar)
raise "src dims" unless src.width == width && src.height == height

# Image#profile returns [columns, rows] -- columns is a Wx1 image of the
# y-positions of the first non-zero pixel down each column, and rows is a
# 1xH image of the x-positions of the first non-zero pixel along each row.
# Edge pixels with no non-zero value in the scan direction take the
# corresponding image dimension as their value.
columns, rows_profile = src.profile

raise "columns dims" unless columns.width == width && columns.height == 1
raise "rows dims"    unless rows_profile.width == 1 && rows_profile.height == height

# Column containing the bright pixel must report row 3; other columns
# report height (no hit).
raise "col(target_x) #{columns.getpoint(target_x, 0)}" unless columns.getpoint(target_x, 0)[0] == target_y.to_f
raise "col(0) #{columns.getpoint(0, 0)}" unless columns.getpoint(0, 0)[0] == height.to_f

# Row containing the bright pixel must report column 5; other rows
# report width (no hit).
raise "row(target_y) #{rows_profile.getpoint(0, target_y)}" unless rows_profile.getpoint(0, target_y)[0] == target_x.to_f
raise "row(0) #{rows_profile.getpoint(0, 0)}" unless rows_profile.getpoint(0, 0)[0] == width.to_f

puts "profile col@x=#{target_x} -> #{columns.getpoint(target_x, 0)[0].to_i}; row@y=#{target_y} -> #{rows_profile.getpoint(0, target_y)[0].to_i}"
RUBY
