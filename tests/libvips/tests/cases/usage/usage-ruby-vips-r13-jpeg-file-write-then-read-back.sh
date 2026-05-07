#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-jpeg-file-write-then-read-back
# @title: ruby-vips write_to_file then new_from_file roundtrip a 12x8 JPEG
# @description: Saves a 12x8 single-band uchar image to a JPEG file via write_to_file and verifies the on-disk file is non-empty, then reloads it with Vips::Image.new_from_file and asserts the reload preserves the 12x8 dimensions, exercising the libvips JPEG file IO path.
# @timeout: 60
# @tags: usage, vips, ruby, jpeg, file-io
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]
out = File.join(tmpdir, 'out.jpg')
img = (Vips::Image.black(12, 8) + 100).cast(:uchar)
img.write_to_file(out)
raise "missing jpeg" unless File.size?(out) && File.size(out) > 0

reload = Vips::Image.new_from_file(out)
raise "jpeg reload dims=#{reload.width}x#{reload.height}" unless reload.width == 12 && reload.height == 8
puts "jpeg file roundtrip #{reload.width}x#{reload.height}"
RUBY
