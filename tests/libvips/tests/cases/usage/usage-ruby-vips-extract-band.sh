#!/usr/bin/env bash
# @testcase: usage-ruby-vips-extract-band
# @title: ruby-vips extract band
# @description: Extracts one band from a multi-band image with ruby-vips.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-extract-band"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(4, 4, bands: 3) + [1, 2, 3]
band = image.extract_band(1)
raise "unexpected bands" unless band.bands == 1
puts "band #{band.avg}"
RUBY
