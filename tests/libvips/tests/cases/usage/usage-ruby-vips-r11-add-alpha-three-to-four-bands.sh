#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-add-alpha-three-to-four-bands
# @title: ruby-vips Image#add_alpha bumps a 3-band image to 4 bands with opaque alpha
# @description: Bandjoins a 3-band uchar image and verifies Image#add_alpha yields a 4-band image whose new band is the type-max (255) opaque alpha.
# @timeout: 60
# @tags: usage, vips, ruby, alpha, bands
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
band = (Vips::Image.black(2, 2) + 100).cast(:uchar)
rgb = band.bandjoin([band, band])
raise "rgb bands #{rgb.bands}" unless rgb.bands == 3
rgba = rgb.add_alpha
raise "rgba bands #{rgba.bands}" unless rgba.bands == 4
alpha = rgba.extract_band(3)
raise "alpha avg #{alpha.avg}" unless alpha.avg == 255.0
puts "add_alpha 3->4 ok, alpha=255"
RUBY
