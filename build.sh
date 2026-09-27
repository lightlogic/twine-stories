#!/usr/bin/env bash
set -euo pipefail

TWEEGO="${TWEEGO:-tweego}"
rm -rf dist && mkdir -p dist

index="dist/index.html"
echo '<!doctype html><meta charset="utf-8"><title>Stories</title><h1>Stories</h1><ul>' > "$index"

for dir in stories/*/; do
  name=$(basename "$dir")
  mkdir -p "dist/$name"
  "$TWEEGO" -o "dist/$name/index.html" "$dir/src"
  [ -d "$dir/assets" ] && cp -r "$dir/assets" "dist/$name/"
  echo "<li><a href=\"$name/\">$name</a></li>" >> "$index"
  echo "Built $name"
done

echo '</ul>' >> "$index"