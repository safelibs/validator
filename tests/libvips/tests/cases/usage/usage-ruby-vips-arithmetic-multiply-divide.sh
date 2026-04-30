#!/usr/bin/env bash
# @testcase: usage-ruby-vips-arithmetic-multiply-divide
# @title: ruby-vips image multiply and divide arithmetic
# @description: Combines two synthetic images with multiply and divide and confirms exact pixel values via getpoint.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

a = (Vips::Image.black(4, 4) + 12).cast(:uchar)
b = (Vips::Image.black(4, 4) + 4).cast(:uchar)

prod = a.multiply(b)
raise "prod 0,0 #{prod.getpoint(0, 0).inspect}" unless prod.getpoint(0, 0) == [48.0]
raise "prod 3,3 #{prod.getpoint(3, 3).inspect}" unless prod.getpoint(3, 3) == [48.0]

quot = a.divide(b)
raise "quot 0,0 #{quot.getpoint(0, 0).inspect}" unless quot.getpoint(0, 0) == [3.0]

out_path = File.join(tmpdir, "prod.tif")
prod.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload size" unless reload.width == 4 && reload.height == 4
puts "arithmetic mul=48 div=3"
RUBY

file "$tmpdir/prod.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF" >&2; exit 1; }
