#!/usr/bin/env bash
set -euo pipefail

# Convert SVGs to PNGs using available tools
# Priority: rsvg-convert > inkscape > ImageMagick (convert) > cairosvg

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

convert_svg() {
  local input="$1"
  local output="$2"
  local width="$3"
  local height="$4"

  if command -v rsvg-convert &>/dev/null; then
    rsvg-convert -w "$width" -h "$height" "$input" -o "$output"
  elif command -v inkscape &>/dev/null; then
    inkscape "$input" --export-type=png --export-filename="$output" -w "$width" -h "$height"
  elif command -v convert &>/dev/null; then
    convert -background none -size "${width}x${height}" "$input" "$output"
  elif command -v cairosvg &>/dev/null; then
    cairosvg "$input" -o "$output" -W "$width" -H "$height"
  else
    echo "ERROR: No SVG-to-PNG converter found."
    echo "Install one of:"
    echo "  brew install librsvg          # rsvg-convert (recommended)"
    echo "  brew install inkscape"
    echo "  brew install imagemagick      # convert"
    echo "  pip install cairosvg"
    exit 1
  fi

  echo "  $input -> $output"
}

echo "Converting SVGs to PNGs..."
convert_svg icon.svg   icon.png   1024 1024
convert_svg splash.svg splash.png  200  200
convert_svg hero.svg   hero.png   1200  630
convert_svg og.svg     og.png     1200  630

echo "Done."
