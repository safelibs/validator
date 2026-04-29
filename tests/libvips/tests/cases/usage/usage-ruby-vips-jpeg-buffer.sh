#!/usr/bin/env bash
# @testcase: usage-ruby-vips-jpeg-buffer
# @title: ruby-vips JPEG buffer
# @description: Encodes a ruby-vips image to JPEG buffer bytes and checks nonempty output.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-jpeg-buffer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(8, 8, bands: 3) + 128
data = image.write_to_buffer(".jpg")
raise "empty jpeg" unless data.bytesize > 0
puts "jpeg-buffer #{data.bytesize}"
RUBY
