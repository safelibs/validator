#!/usr/bin/env bash
# @testcase: usage-ruby-vips-write-buffer
# @title: ruby-vips writes buffer
# @description: Writes a PNG image to an in-memory buffer with ruby-vips.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-write-buffer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(5, 5, bands: 3) + 64
data = image.write_to_buffer(".png")
raise "empty buffer" unless data.bytesize > 0
puts "buffer #{data.bytesize}"
RUBY
