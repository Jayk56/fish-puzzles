# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fish Puzzles is a kid-friendly point-and-click adventure game for iOS built with SpriteKit and Swift. The game targets children aged 4-9 with a focus on safety, privacy (COPPA compliant), and 60 FPS performance across all iOS devices.

## Development Commands
For all make commands, you must run them after changing into the fish-puzzles project folder first.

### Building and Running
```bash
# Build the project
make build

# Run in simulator (iPhone 16)
make run

# Build for release
make release

# Create App Store archive
make archive
```

### Testing
```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run UI tests only
make test-ui

# Run with performance profiling
make profile
```

### Code Quality
```bash
# Run SwiftLint
make lint

# Format code with SwiftFormat (if installed)
make format
```

### Asset Management
```bash
# Generate texture atlases
make atlases

# Create a new scene
./Scripts/create_scene.sh SceneName
```

### Utilities
```bash
# Clean build artifacts
make clean

# Initial project setup
make setup
```

## Architecture

The project uses an Entity-Component System (ECS) architecture with modular subsystems:

### Core Components
- **Entity**: Base class for game objects with component management (`fish-puzzles/Core/ECS/Entity.swift`)
- **Component**: Base protocol for attachable behaviors (`fish-puzzles/Core/ECS/`)
- **GameEngine**: Central game loop and system coordination (`fish-puzzles/Core/GameEngine/`)
- **GameState**: State machine for game flow (`fish-puzzles/Core/State/`)

### Key Systems
- **SceneManager**: Handles scene transitions and lifecycle (`fish-puzzles/Scenes/Base/SceneManager.swift`)
- **InteractionSystem**: Touch/gesture handling (`fish-puzzles/Systems/Interaction/`)
- **AudioManager**: Music, VO, and SFX management (`fish-puzzles/Systems/Audio/`)
- **SaveManager**: Local and CloudKit persistence (`fish-puzzles/Systems/Save/`)
- **AssetManager**: Resource loading and caching (`fish-puzzles/Utilities/Helpers/`)

### Scene Structure
All game scenes inherit from `BaseGameScene` and follow this pattern:
1. Scene initialization in `didMove(to:)`
2. Touch handling via `handleTouch(at:)`
3. Entity updates in game loop
4. Transition management through SceneManager

## Key Technical Constraints

### Performance Requirements
- Must maintain 60 FPS on all supported devices (iOS 16+)
- Memory budget: <200MB active footprint
- Scene load time: <1 second
- Texture atlas max size: 2048x2048

### Safety & Privacy
- No external network calls except CloudKit
- No user-generated content
- Parental gates on all external actions
- COPPA compliant - no PII collection

### Accessibility
- Full VoiceOver support required
- Dynamic type support
- High contrast mode
- Reduced motion options

## Current Issues

The `CharacterAnimationComponent.swift` has several compilation errors:
- Missing `Component` protocol import/definition
- `AssetManager` not found in scope
- Missing entity property access

When fixing these, ensure components properly inherit from the base `Component` class defined in `Entity.swift`.

## Testing Approach

The project uses XCTest framework with:
- Unit tests in `fish-puzzlesTests/`
- UI tests in `fish-puzzlesUITests/`
- Test on iPhone 16 simulator by default
- Performance profiling via Instruments

## Asset Pipeline

Assets are organized as:
- `Assets/Art/` - Sprites and backgrounds
- `Assets/Audio/` - Music, SFX, and voice-over
- `Assets/Data/` - Scene definitions and dialogue
- `ProcessedAssets/` - Generated texture atlases

Texture atlases are generated via Python script in `Scripts/generate_atlases.py`.