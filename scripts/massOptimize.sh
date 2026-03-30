#!/bin/bash

# This script trys to clean up the mass SVG exports from Inkscape
# Before running this script, open the current markers/*.svg file in Inkscape and use the batch export feature
# to export all groups as individual SVG files in public/markers. Then run this script *in* the public/markers folder

inkscape --actions="select-by-selector:svg>g; selection-ungroup; select-by-selector:svg>g; selection-ungroup; select-by-selector:svg>g; selection-ungroup; select-by-selector:text; object-to-path" --export-plain-svg --export-overwrite *.svg

# Manual clean-up of the SVG files
for file in *.svg; do
  # Check if any .svg files exist to avoid errors in empty directories
  [ -e "$file" ] || continue

  sed -i \
    -e "s/font-size:46.6666px//g" \
    -e "s/font-weight:700//g" \
    -e "s/font-family:'DejaVu Sans'//g" \
    -e "s/-inkscape-font-specification:'DejaVu Sans Bold'//g" \
    -e "s/stroke-dasharray:none//g" \
    -e "s/stroke-opacity:1//g" \
    -e "s/fill-opacity:1//g" \
    -e "/stroke:/!s/stroke-width:.999999//g" \
    "$file"
done

bunx svgo -f . -p 2 --pretty
