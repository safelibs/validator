#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-png-jpeg-roundtrip
# @title: ruby-vips PNG to JPEG roundtrip
# @description: Writes a generated 32x32 RGB image to PNG, reloads it, writes JPEG, reloads JPEG and verifies dimensions and band count are preserved.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]
src = Vips::Image.black(32, 32, bands: 3) + [10, 20, 30]
src = src.cast(:uchar)

png = File.join(tmpdir, 'out.png')
jpg = File.join(tmpdir, 'out.jpg')
src.write_to_file(png)
loaded = Vips::Image.new_from_file(png)
raise "png dim #{loaded.width}x#{loaded.height}" unless loaded.width == 32 && loaded.height == 32
raise "png bands #{loaded.bands}" unless loaded.bands == 3

loaded.write_to_file(jpg, Q: 85)
again = Vips::Image.new_from_file(jpg)
raise "jpg dim #{again.width}x#{again.height}" unless again.width == 32 && again.height == 32
raise "jpg bands #{again.bands}" unless again.bands == 3
RUBY

file "$tmpdir/out.png" | grep -q 'PNG image data'
file "$tmpdir/out.jpg" | grep -q 'JPEG image data'
