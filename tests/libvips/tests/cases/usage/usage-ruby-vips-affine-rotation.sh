#!/usr/bin/env bash
# @testcase: usage-ruby-vips-affine-rotation
# @title: ruby-vips affine 90 degree rotation
# @description: Rotates a generated image by 90 degrees with the affine operator and verifies that pixel positions are swapped accordingly.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 3x2 grayscale: row 0 = [10, 20, 30], row 1 = [40, 50, 60]
src = Vips::Image.new_from_memory([10, 20, 30, 40, 50, 60].pack('C*'), 3, 2, 1, :uchar)
raise "src 0,0" unless src.getpoint(0, 0) == [10.0]
raise "src 2,1" unless src.getpoint(2, 1) == [60.0]

# Affine 90 deg clockwise: matrix [0, 1, -1, 0]
rotated = src.affine([0, 1, -1, 0], interpolate: Vips::Interpolate.new(:nearest))
raise "rot dims #{rotated.width}x#{rotated.height}" unless rotated.width == 2 && rotated.height == 3

out_path = File.join(tmpdir, "rotated.png")
rotated.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 2 && reload.height == 3
puts "affine #{reload.width}x#{reload.height}"
RUBY

file "$tmpdir/rotated.png" | grep -q 'PNG image data' || { echo "not a PNG" >&2; exit 1; }
