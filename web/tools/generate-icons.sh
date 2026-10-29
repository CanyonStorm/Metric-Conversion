#!/bin/sh
set -eu

cd "$(dirname "$0")/../public"
mkdir -p icons
for size in 180 192 512; do
  name="icon-$size.png"
  if [ "$size" = 180 ]; then name="apple-touch-icon.png"; fi
  sips -s format png -z "$size" "$size" icon.svg --out "icons/$name"
done
