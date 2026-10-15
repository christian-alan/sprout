#!/bin/zsh
set -euo pipefail

source_root="/Users/work/Desktop/sprout-ios-handoff/assets/mascots/png"
catalog_root="/Users/work/Documents/ChatGPT/sprout/sprout-personal-assistant/Assets.xcassets"

for source_file in "$source_root"/{full,head}/*.png; do
  filename="${source_file:t}"
  asset_name="${filename%@3x.png}"
  imageset="$catalog_root/$asset_name.imageset"
  mkdir -p "$imageset"
  cp "$source_file" "$imageset/$filename"
  /usr/bin/python3 - "$imageset/Contents.json" "$filename" <<'PY'
import json
import sys

path, filename = sys.argv[1:]
payload = {
    "images": [
        {"idiom": "universal", "scale": "1x"},
        {"idiom": "universal", "scale": "2x"},
        {"filename": filename, "idiom": "universal", "scale": "3x"},
    ],
    "info": {"author": "xcode", "version": 1},
}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY
done
