#!/usr/bin/env python3

import os
import subprocess
import json
from pathlib import Path

def generate_atlas(input_dir, output_name, output_dir):
    """Generate a texture atlas using TexturePacker or similar tool"""
    print(f"Generating atlas: {output_name}")
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # This is a placeholder - integrate with your texture packing tool
    # Example for TexturePacker:
    # subprocess.run([
    #     "TexturePacker",
    #     "--format", "spritekit-swift",
    #     "--max-size", "2048",
    #     "--size-constraints", "POT",
    #     "--pack-mode", "Best",
    #     "--data", f"{output_dir}/{output_name}.atlasc/{output_name}.plist",
    #     "--sheet", f"{output_dir}/{output_name}.atlasc/{output_name}.png",
    #     input_dir
    # ])
    
    # Alternative: Create .spriteatlas directories for Xcode's built-in atlas generation
    atlas_dir = f"{output_dir}/{output_name}.spriteatlas"
    os.makedirs(atlas_dir, exist_ok=True)
    print(f"✓ Created atlas directory: {atlas_dir}")
    print(f"  Copy images from {input_dir} to {atlas_dir} for Xcode atlas generation")

def main():
    # Base paths
    assets_base = "fish-puzzles/Resources/Assets.xcassets"
    raw_assets_base = "Assets"
    
    # Define atlases to generate
    atlases = {
        "Location1": f"{raw_assets_base}/Art/Backgrounds/Location1",
        "Location2": f"{raw_assets_base}/Art/Backgrounds/Location2",
        "Characters": f"{raw_assets_base}/Art/Characters",
        "UI": f"{raw_assets_base}/Art/UI",
        "Items": f"{raw_assets_base}/Art/Items"
    }
    
    for atlas_name, source_dir in atlases.items():
        if os.path.exists(source_dir):
            generate_atlas(source_dir, atlas_name, assets_base)
        else:
            print(f"⚠️  Source directory not found: {source_dir}")
            print(f"   Expected at: {os.path.abspath(source_dir)}")

if __name__ == "__main__":
    main()
