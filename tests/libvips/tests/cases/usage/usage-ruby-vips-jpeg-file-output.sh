#!/usr/bin/env bash
# @testcase: usage-ruby-vips-jpeg-file-output
# @title: ruby-vips JPEG file output
# @description: Saves a synthetic JPEG with ruby-vips, reloads it, and checks the output file is nonempty.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-jpeg-file-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(8, 6, bands: 3) + 90
path = File.join(tmpdir, "image.jpg")
image.write_to_file(path)
reload = Vips::Image.new_from_file(path)
raise "unexpected jpeg output" unless File.size(path) > 0 && reload.width == 8 && reload.height == 6
puts "jpeg #{File.size(path)}"
RUBY
