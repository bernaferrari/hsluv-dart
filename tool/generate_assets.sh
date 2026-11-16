#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

rm -rf build/readme_frames
flutter test tool/render_readme_assets.dart

encode_webp() {
  local name="$1"
  local quality="$2"
  local src="build/readme_frames/$name"
  local scaled="build/readme_frames/${name}_960"
  mkdir -p "$scaled"
  ffmpeg -y -loglevel error -i "$src/frame_%04d.png" -vf "scale=960:-1:flags=lanczos" "$scaled/frame_%04d.png"
  img2webp -min_size -loop 0 -d 33 -lossy -q "$quality" -m 4 "$scaled"/frame_*.png -o "assets/$name.webp"
}

encode_webp hsluv_vs_hsl_solid 82
encode_webp hpluv_vs_hsluv_solid 82
encode_webp hsl_vs_hsluv 84

rm -rf build/readme_frames
ls -lh assets/logo.png assets/hsluv_vs_hsl_solid.webp assets/hpluv_vs_hsluv_solid.webp assets/hsl_vs_hsluv.webp
