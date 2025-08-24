#!/usr/bin/env python3

"""
Slice a grid-based sprite sheet PNG into per-frame images and scaffold
an Xcode .spriteatlas with properly named .imageset entries.

Dependencies: macOS 'sips' (built-in). No Python imaging libraries required.

Example:
  python3 Scripts/slice_spritesheet_to_spriteatlas.py \
    --input fish-puzzles/Assets.xcassets/FishCharacter.spriteatlas/sprite-sheet-blue-fish.imageset/sprite-sheet-blue-fish.png \
    --rows 3 --cols 3 \
    --atlas FishCharacter \
    --basename fish \
    --assets fish-puzzles/Assets.xcassets \
    --origin top-left

This creates:
  fish-puzzles/Assets.xcassets/FishCharacter.spriteatlas/
    fish_01.imageset/{fish_01.png, Contents.json}
    ...

Notes:
- The --origin flag controls how rows are counted in the sheet:
  top-left counts row 0 at the top; bottom-left counts row 0 at the bottom.
- If your current sheet appears vertically inverted on device, try switching
  the origin, or re-export the sheet upright and set origin top-left.
"""

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
from pathlib import Path


def run(cmd: list[str]) -> None:
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        sys.stderr.write(f"Command failed: {' '.join(cmd)}\n{res.stderr}\n")
        sys.exit(res.returncode)


def query_image_size(path: Path) -> tuple[int, int]:
    # sips -g pixelHeight -g pixelWidth
    res = subprocess.run(["sips", "-g", "pixelHeight", "-g", "pixelWidth", str(path)],
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        sys.stderr.write(res.stderr)
        sys.exit(res.returncode)
    h = None
    w = None
    for line in res.stdout.splitlines():
        if "pixelHeight:" in line:
            h = int(line.split(":")[-1].strip())
        if "pixelWidth:" in line:
            w = int(line.split(":")[-1].strip())
    if h is None or w is None:
        sys.stderr.write("Failed to query image size via sips\n")
        sys.exit(1)
    return h, w


def write_imageset(dest_dir: Path, filename: str) -> None:
    dest_dir.mkdir(parents=True, exist_ok=True)
    contents = {
        "images": [
            {"idiom": "universal", "scale": "1x", "filename": filename},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"version": 1, "author": "xcode"},
    }
    (dest_dir / "Contents.json").write_text(json.dumps(contents, indent=2))


def main() -> None:
    ap = argparse.ArgumentParser(description="Slice a grid spritesheet into a .spriteatlas")
    ap.add_argument("--input", required=True, help="Path to input PNG spritesheet")
    ap.add_argument("--rows", type=int, required=True, help="Number of rows in the grid")
    ap.add_argument("--cols", type=int, required=True, help="Number of columns in the grid")
    ap.add_argument("--atlas", required=True, help="Atlas name (folder under Assets.xcassets)")
    ap.add_argument("--basename", required=True, help="Base name for frames, e.g., 'fish' -> fish_01.png")
    ap.add_argument("--assets", default="fish-puzzles/Assets.xcassets", help="Path to Assets.xcassets root")
    ap.add_argument("--origin", choices=["top-left", "bottom-left"], default="top-left",
                    help="Row 0 position in the source sheet")
    ap.add_argument("--start-index", type=int, default=1, help="Starting frame index (default 1)")
    args = ap.parse_args()

    sheet = Path(args.input)
    if not sheet.exists():
        sys.stderr.write(f"Input not found: {sheet}\n")
        sys.exit(1)

    assets_root = Path(args.assets)
    if not assets_root.exists():
        sys.stderr.write(f"Assets.xcassets not found: {assets_root}\n")
        sys.exit(1)

    atlas_dir = assets_root / f"{args.atlas}.spriteatlas"
    atlas_dir.mkdir(parents=True, exist_ok=True)

    pixel_h, pixel_w = query_image_size(sheet)
    if pixel_w % args.cols != 0 or pixel_h % args.rows != 0:
        sys.stderr.write(
            f"Warning: sheet size {pixel_w}x{pixel_h} not divisible by grid {args.cols}x{args.rows}.\n"
            "Cropping will floor to integer frame sizes; last column/row may lose pixels.\n"
        )

    frame_w = pixel_w // args.cols
    frame_h = pixel_h // args.rows

    # sips uses: -c pixelsH pixelsW  and  --cropOffset offsetY offsetH (per `sips -h`).
    # We'll compute offsets for each frame based on origin.
    index = args.start_index
    for r in range(args.rows):
        # Map row index according to origin
        src_r = r if args.origin == "top-left" else (args.rows - 1 - r)
        for c in range(args.cols):
            y_off = src_r * frame_h
            x_off = c * frame_w
            frame_name = f"{args.basename}_{index:02d}.png"
            out_imageset = atlas_dir / f"{args.basename}_{index:02d}.imageset"
            out_png = out_imageset / frame_name

            # Prepare imageset
            write_imageset(out_imageset, frame_name)

            # Crop using sips
            # Note: sips requires output path to exist parent-wise
            run([
                "sips",
                "-s", "format", "png",
                "-c", str(frame_h), str(frame_w),
                "--cropOffset", str(y_off), str(x_off),
                str(sheet),
                "-o", str(out_png)
            ])

            index += 1

    print(f"✓ Created per-frame atlas at: {atlas_dir}")
    print("Next steps:")
    print("- Remove or ignore the original grid-based imageset to avoid duplicate assets in the atlas.")
    print("- In code, load frames via SKTextureAtlas(named: '<atlas>').textureNames.sorted().")


if __name__ == "__main__":
    main()

