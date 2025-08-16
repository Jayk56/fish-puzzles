#!/bin/bash

# Fish Puzzles - Project Setup Script
# This script integrates the modular architecture with the existing Xcode project

set -e

echo "🐠 Fish Puzzles - Project Setup"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -d "fish-puzzles/fish-puzzles.xcodeproj" ]; then
    echo -e "${RED}Error: fish-puzzles.xcodeproj not found!${NC}"
    echo "Please run this script from the fish-puzzles root directory"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found existing Xcode project"

# Function to create directory with message
create_dir() {
    mkdir -p "$1"
    echo -e "${GREEN}✓${NC} Created: $1"
}

# Function to create file with content
create_file() {
    echo "$2" > "$1"
    echo -e "${GREEN}✓${NC} Created: $1"
}

echo ""
echo "📁 Creating modular structure alongside existing project..."

# Create module directories inside fish-puzzles folder
create_dir "fish-puzzles/Modules/GameCore/Sources/ECS"
create_dir "fish-puzzles/Modules/GameCore/Sources/Protocols"
create_dir "fish-puzzles/Modules/GameCore/Tests"
create_dir "fish-puzzles/Modules/GameCore/Resources"

create_dir "fish-puzzles/Modules/SceneManagement/Sources/Scenes"
create_dir "fish-puzzles/Modules/SceneManagement/Sources/Transitions"
create_dir "fish-puzzles/Modules/SceneManagement/Tests"
create_dir "fish-puzzles/Modules/SceneManagement/Resources"

create_dir "fish-puzzles/Modules/InteractionSystem/Sources/Components"
create_dir "fish-puzzles/Modules/InteractionSystem/Tests"

create_dir "fish-puzzles/Modules/InventorySystem/Sources/UI"
create_dir "fish-puzzles/Modules/InventorySystem/Sources/Components"
create_dir "fish-puzzles/Modules/InventorySystem/Tests"

create_dir "fish-puzzles/Modules/AudioSystem/Sources/Models"
create_dir "fish-puzzles/Modules/AudioSystem/Tests"

create_dir "fish-puzzles/Modules/SaveSystem/Sources/Models"
create_dir "fish-puzzles/Modules/SaveSystem/Sources/Serialization"
create_dir "fish-puzzles/Modules/SaveSystem/Tests"

create_dir "fish-puzzles/Modules/AssetPipeline/Sources/Loaders"
create_dir "fish-puzzles/Modules/AssetPipeline/Tests"
create_dir "fish-puzzles/Modules/AssetPipeline/Tools"

create_dir "fish-puzzles/Modules/Analytics/Sources/Events"
create_dir "fish-puzzles/Modules/Analytics/Tests"

create_dir "fish-puzzles/Modules/UIComponents/Sources/Screens"
create_dir "fish-puzzles/Modules/UIComponents/Sources/HUD"
create_dir "fish-puzzles/Modules/UIComponents/Sources/Components"
create_dir "fish-puzzles/Modules/UIComponents/Tests"

create_dir "fish-puzzles/Modules/Localization/Sources"
create_dir "fish-puzzles/Modules/Localization/Resources/en.lproj"
create_dir "fish-puzzles/Modules/Localization/Tests"

create_dir "fish-puzzles/Modules/Accessibility/Sources/Traits"
create_dir "fish-puzzles/Modules/Accessibility/Tests"

# Create asset directories (at root level, outside fish-puzzles/)
create_dir "Assets/Art/Characters"
create_dir "Assets/Art/Backgrounds"
create_dir "Assets/Art/Items"
create_dir "Assets/Art/UI"
create_dir "Assets/Audio/Music"
create_dir "Assets/Audio/VO/en"
create_dir "Assets/Audio/SFX"
create_dir "Assets/Data/Scenes"
create_dir "Assets/Data/Puzzles"
create_dir "Assets/Data/Dialogue"

# Create build/config directories inside fish-puzzles/
create_dir "fish-puzzles/Configuration"
create_dir "Scripts/ci"
create_dir "fish-puzzles/Templates"
create_dir "ProcessedAssets"

echo ""
echo "📝 Creating configuration files..."

# Create Package.swift at root level
create_file "fish-puzzles/Package.swift" '// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FishPuzzles",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "GameCore", targets: ["GameCore"]),
        .library(name: "SceneManagement", targets: ["SceneManagement"]),
        .library(name: "InteractionSystem", targets: ["InteractionSystem"]),
        .library(name: "InventorySystem", targets: ["InventorySystem"]),
        .library(name: "AudioSystem", targets: ["AudioSystem"]),
        .library(name: "SaveSystem", targets: ["SaveSystem"]),
        .library(name: "AssetPipeline", targets: ["AssetPipeline"]),
        .library(name: "Analytics", targets: ["Analytics"]),
        .library(name: "UIComponents", targets: ["UIComponents"]),
        .library(name: "Localization", targets: ["Localization"]),
        .library(name: "Accessibility", targets: ["Accessibility"])
    ],
    dependencies: [],
    targets: [
        .target(name: "GameCore", dependencies: []),
        .target(name: "SceneManagement", dependencies: ["GameCore", "AssetPipeline"]),
        .target(name: "InteractionSystem", dependencies: ["GameCore"]),
        .target(name: "InventorySystem", dependencies: ["GameCore"]),
        .target(name: "AudioSystem", dependencies: []),
        .target(name: "SaveSystem", dependencies: []),
        .target(name: "AssetPipeline", dependencies: []),
        .target(name: "Analytics", dependencies: []),
        .target(name: "UIComponents", dependencies: ["Accessibility", "Localization"]),
        .target(name: "Localization", dependencies: []),
        .target(name: "Accessibility", dependencies: []),
        
        .testTarget(name: "GameCoreTests", dependencies: ["GameCore"]),
        .testTarget(name: "SceneManagementTests", dependencies: ["SceneManagement"]),
        .testTarget(name: "InteractionSystemTests", dependencies: ["InteractionSystem"]),
        .testTarget(name: "InventorySystemTests", dependencies: ["InventorySystem"]),
        .testTarget(name: "AudioSystemTests", dependencies: ["AudioSystem"]),
        .testTarget(name: "SaveSystemTests", dependencies: ["SaveSystem"]),
        .testTarget(name: "AssetPipelineTests", dependencies: ["AssetPipeline"]),
        .testTarget(name: "AnalyticsTests", dependencies: ["Analytics"]),
        .testTarget(name: "UIComponentsTests", dependencies: ["UIComponents"]),
        .testTarget(name: "LocalizationTests", dependencies: ["Localization"]),
        .testTarget(name: "AccessibilityTests", dependencies: ["Accessibility"])
    ]
)'

# Create .gitignore
create_file ".gitignore" '# Xcode
#
build/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/
*.xccheckout
*.moved-aside
DerivedData/
*.hmap
*.ipa
*.xcuserstate
.DS_Store

# Swift Package Manager
.build/
Package.resolved
*.xcodeproj

# Large Assets (use Git LFS)
Assets/Art/**/*.png
Assets/Art/**/*.jpg
Assets/Audio/**/*.wav
Assets/Audio/**/*.mp3
Assets/Audio/**/*.m4a
ProcessedAssets/

# Secrets
*.p12
*.mobileprovision
.env
Config.xcconfig'

# Create .swiftlint.yml at project root
create_file "fish-puzzles/.swiftlint.yml" 'disabled_rules:
  - trailing_whitespace
  - line_length
  
opt_in_rules:
  - force_unwrapping
  - implicitly_unwrapped_optional
  - empty_count
  - closure_end_indentation
  - closure_spacing
  - collection_alignment
  - contains_over_filter_count
  - discouraged_object_literal
  - empty_string
  - fallthrough
  - first_where
  - joined_default_parameter
  - last_where
  - literal_expression_end_indentation
  - multiline_arguments
  - multiline_function_chains
  - multiline_literal_brackets
  - multiline_parameters
  - multiline_parameters_brackets
  - operator_usage_whitespace
  - optional_enum_case_matching
  - prefer_self_type_over_type_of_self
  - prefer_zero_over_explicit_init
  - redundant_nil_coalescing
  - redundant_type_annotation
  - sorted_first_last
  - trailing_closure
  - unneeded_parentheses_in_closure_argument
  - vertical_parameter_alignment_on_call
  - vertical_whitespace_closing_braces
  - vertical_whitespace_opening_braces
  - yoda_condition

line_length:
  warning: 100
  error: 120
  ignores_function_declarations: true
  ignores_comments: true

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1000

function_body_length:
  warning: 50
  error: 100

cyclomatic_complexity:
  warning: 10
  error: 20

identifier_name:
  min_length:
    warning: 2
  max_length:
    warning: 40
    error: 50
  excluded:
    - id
    - x
    - y
    - z

excluded:
  - Pods/
  - .build/
  - DerivedData/
  - ProcessedAssets/'

# Create Makefile
create_file "Makefile" '.PHONY: all setup build test run clean atlases lint format help

all: clean build test

help: ## Show this help message
	@echo "Fish Puzzles - Build Commands"
	@echo ""
	@grep -E "^[a-zA-Z_-]+:.*?## .*$$" $(MAKEFILE_LIST) | sort | awk "BEGIN {FS = \":.*?## \"}; {printf \"\\033[36m%-15s\\033[0m %s\\n\", \$$1, \$$2}"

setup: ## Initial project setup
	@echo "Setting up project..."
	@swift package resolve
	@if ! command -v swiftlint &> /dev/null; then \\
		echo "Installing SwiftLint..."; \\
		brew install swiftlint; \\
	fi
	@if ! command -v xcbeautify &> /dev/null; then \\
		echo "Installing xcbeautify..."; \\
		brew install xcbeautify; \\
	fi

build: ## Build the project
	@echo "Building project..."
	@swift build

test: ## Run all tests
	@echo "Running tests..."
	@swift test

run: ## Run the app in simulator
	@echo "Running app..."
	@open -a Simulator
	@sleep 2
	@xcodebuild -scheme FishPuzzles -destination "platform=iOS Simulator,name=iPhone 15" run | xcbeautify

clean: ## Clean build artifacts
	@echo "Cleaning..."
	@swift package clean
	@rm -rf .build
	@rm -rf DerivedData
	@rm -rf ProcessedAssets

atlases: ## Generate texture atlases
	@echo "Generating texture atlases..."
	@python3 Scripts/generate_atlases.py

lint: ## Run SwiftLint
	@echo "Linting code..."
	@swiftlint

format: ## Format code with SwiftFormat
	@echo "Formatting code..."
	@if command -v swiftformat &> /dev/null; then \\
		swiftformat . --swiftversion 5.9; \\
	else \\
		echo "SwiftFormat not installed. Install with: brew install swiftformat"; \\
	fi

debug: ## Build and run in debug mode
	@echo "Running in debug mode..."
	@swift build -c debug
	@swift run -c debug

release: ## Build for release
	@echo "Building release..."
	@swift build -c release

profile: ## Run with performance profiling
	@echo "Running with profiling..."
	@xcodebuild -scheme FishPuzzles -enableCodeCoverage YES -enableAddressSanitizer YES test | xcbeautify'

# Create README
create_file "README.md" '# 🐠 Fish Puzzles

A kid-friendly point-and-click adventure game for iOS, built with native Swift and SpriteKit.

## Overview

Fish Puzzles is a whimsical, story-driven 2D adventure game designed for children aged 4-9. Players explore underwater worlds, solve simple puzzles, and interact with friendly sea creatures in a safe, educational environment.

## Features

- 🎮 Native iOS implementation using SpriteKit
- 🔒 Privacy-first design (COPPA compliant)
- ☁️ CloudKit save synchronization
- 🎯 60 FPS performance on all devices
- ♿ Full accessibility support
- 🌍 Localization-ready architecture
- 📱 Universal app (iPhone & iPad)

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- macOS Ventura or later

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourteam/fish-puzzles.git
cd fish-puzzles

# Run setup script
./setup.sh

# Install dependencies and build
make setup
make build

# Run tests
make test

# Run in simulator
make run
```

## Architecture

The project uses a modular architecture with the following key components:

- **GameCore**: Core game engine and ECS
- **SceneManagement**: Scene lifecycle and transitions
- **InteractionSystem**: Touch and gesture handling
- **InventorySystem**: Item management
- **AudioSystem**: Music, VO, and SFX
- **SaveSystem**: Local and cloud persistence
- **AssetPipeline**: Resource loading and caching

See [architecture/README.md](architecture/README.md) for detailed documentation.

## Development

### Creating a New Scene

```bash
./Scripts/create_scene.sh MyNewScene
```

### Running Tests

```bash
make test
```

### Building for Release

```bash
make release
```

## Documentation

- [Architecture Documentation](architecture/)
- [API Documentation](docs/api/)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)

## License

Copyright © 2024 Fish Puzzles Team. All rights reserved.

## Support

For questions or issues, please contact the development team or create an issue in the repository.'

echo ""
echo "🔧 Creating build scripts..."

# Create atlas generation script
create_file "Scripts/generate_atlases.py" '#!/usr/bin/env python3

import os
import subprocess
import json
from pathlib import Path

def generate_atlas(input_dir, output_name):
    """Generate a texture atlas using TexturePacker or similar tool"""
    print(f"Generating atlas: {output_name}")
    
    # This is a placeholder - integrate with your texture packing tool
    # Example for TexturePacker:
    # subprocess.run([
    #     "TexturePacker",
    #     "--format", "spritekit-swift",
    #     "--max-size", "2048",
    #     "--size-constraints", "POT",
    #     "--pack-mode", "Best",
    #     "--data", f"ProcessedAssets/{output_name}.plist",
    #     "--sheet", f"ProcessedAssets/{output_name}.png",
    #     input_dir
    # ])
    
    print(f"✓ Generated {output_name}")

def main():
    # Define atlases to generate
    atlases = {
        "Location1": "Assets/Art/Backgrounds/Location1",
        "Location2": "Assets/Art/Backgrounds/Location2",
        "Characters": "Assets/Art/Characters",
        "UI": "Assets/Art/UI",
        "Items": "Assets/Art/Items"
    }
    
    for atlas_name, source_dir in atlases.items():
        if os.path.exists(source_dir):
            generate_atlas(source_dir, atlas_name)
        else:
            print(f"⚠️  Source directory not found: {source_dir}")

if __name__ == "__main__":
    main()'

chmod +x Scripts/generate_atlases.py

# Create scene creation script
create_file "Scripts/create_scene.sh" '#!/bin/bash

SCENE_NAME=$1

if [ -z "$SCENE_NAME" ]; then
    echo "Usage: ./create_scene.sh SceneName"
    exit 1
fi

echo "Creating scene: $SCENE_NAME"

# Create scene file
cat > "fish-puzzles/Modules/SceneManagement/Sources/Scenes/${SCENE_NAME}Scene.swift" << EOF
import SpriteKit
import GameCore

class ${SCENE_NAME}Scene: BaseGameScene {
    // MARK: - Properties
    private var background: SKSpriteNode!
    private var hotspots: [Hotspot] = []
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
    }
    
    private func setupScene() {
        // Setup background
        background = SKSpriteNode(texture: AssetLoader.shared.texture("${SCENE_NAME}_bg"))
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(background)
        
        // Setup hotspots
        setupHotspots()
        
        // Setup audio
        AudioManager.shared.playMusic(.${SCENE_NAME}Theme)
    }
    
    private func setupHotspots() {
        // Add interactive elements
    }
    
    // MARK: - Interactions
    override func handleTouch(at point: CGPoint) {
        // Handle touch interactions
    }
}
EOF

# Create test file
cat > "fish-puzzles/Modules/SceneManagement/Tests/${SCENE_NAME}SceneTests.swift" << EOF
import XCTest
@testable import SceneManagement

final class ${SCENE_NAME}SceneTests: XCTestCase {
    var scene: ${SCENE_NAME}Scene!
    
    override func setUp() {
        super.setUp()
        scene = ${SCENE_NAME}Scene(size: CGSize(width: 1024, height: 768))
    }
    
    override func tearDown() {
        scene = nil
        super.tearDown()
    }
    
    func testSceneInitialization() {
        XCTAssertNotNil(scene)
        XCTAssertEqual(scene.size.width, 1024)
        XCTAssertEqual(scene.size.height, 768)
    }
}
EOF

echo "✓ Created ${SCENE_NAME}Scene.swift"
echo "✓ Created ${SCENE_NAME}SceneTests.swift"'

chmod +x Scripts/create_scene.sh

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📚 Next steps:"
echo "  1. Open fish-puzzles.xcodeproj in Xcode"
echo "  2. Add the created modules to your project:"
echo "     - Select project navigator"
echo "     - Right-click and choose 'Add Files to fish-puzzles'"
echo "     - Select the Modules folder"
echo "  3. Enable capabilities in project settings:"
echo "     - SpriteKit (already enabled)"
echo "     - CloudKit"
echo "     - In-App Purchase (if needed)"
echo "  4. Configure bundle identifier if needed"
echo "  5. Run 'make build' to verify setup"
echo ""
echo "📖 Documentation:"
echo "  - Architecture: architecture/README.md"
echo "  - Implementation Guide: architecture/IMPLEMENTATION_GUIDE.md"
echo "  - ADRs: architecture/adr/"
echo ""
echo "🐠 Happy coding!"