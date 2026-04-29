#!/usr/bin/env bash
# @testcase: usage-ruby-vips-resize-sample-png
# @title: ruby-vips resize sample PNG
# @description: Loads a PNG fixture with ruby-vips, resizes it, and verifies the dimensions shrink.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-resize-sample-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

path = File.join(sample_root, "test/test-suite/images/sample.png")
image = Vips::Image.new_from_file(path)
out = image.resize(0.5)
raise "unexpected resize" unless out.width < image.width && out.height < image.height
puts "resize #{out.width}x#{out.height}"
RUBY
