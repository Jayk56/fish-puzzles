# 🐠 Fish Puzzles - iOS Game

A kid-friendly point-and-click adventure game built natively for iOS using SpriteKit.

## Project Structure

This is a pure Xcode project optimized for iOS game development with SpriteKit.

```
fish-puzzles/
├── fish-puzzles.xcodeproj    # Xcode project file
├── fish-puzzles/
│   ├── Core/                 # Game engine and core systems
│   │   ├── GameEngine/       # Main game loop and lifecycle
│   │   ├── ECS/              # Entity-Component System
│   │   └── State/            # Game state management
│   ├── Scenes/               # All game scenes
│   │   ├── Base/             # Base scene class and manager
│   │   ├── MainMenu/         # Main menu
│   │   ├── Location1/        # First game location
│   │   └── Location2/        # Second game location
│   ├── Systems/              # Game systems
│   │   ├── Audio/            # Music, SFX, and voice-over
│   │   ├── Interaction/      # Touch and hotspot handling
│   │   ├── Inventory/        # Item management
│   │   ├── Save/             # Save system with CloudKit
│   │   └── Analytics/        # Privacy-safe analytics
│   ├── UI/                   # User interface
│   │   ├── HUD/              # Heads-up display
│   │   ├── Menus/            # Game menus
│   │   └── Dialogue/         # Dialogue system
│   ├── Utilities/            # Helper classes
│   │   ├── Extensions/       # Swift extensions
│   │   ├── Helpers/          # Utility functions
│   │   └── Constants/        # Game constants
│   └── Resources/            # Game resources
│       ├── Assets.xcassets   # Images and colors
│       ├── Audio/            # Sound files
│       └── Particles/        # Particle effects
└── Assets/                   # Raw assets (not in git)
    ├── Art/                  # Original artwork
    └── Audio/                # Original audio files
```

## Quick Start

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ SDK
- macOS Ventura or later

### Setup
```bash
# Run the setup script
./setup_xcode.sh

# Install build tools
make setup
```

### Building
```bash
# Build the project
make build

# Run in simulator
make run

# Run tests
make test
```

### Adding Files to Xcode
1. Open `fish-puzzles.xcodeproj` in Xcode
2. In Finder, select all the new Swift files created in `fish-puzzles/fish-puzzles/`
3. Drag them into the Xcode project navigator
4. Ensure "Copy items if needed" is **unchecked**
5. Add to target: `fish-puzzles`
6. Click "Finish"

## Architecture

### Core Systems

#### GameEngine
- Singleton that manages the game lifecycle
- Handles scene transitions
- Manages global game state

#### Entity-Component System (ECS)
- `Entity`: Container for components
- `Component`: Data and behavior units
- Flexible composition over inheritance

#### State Management
- `GameState`: Central game state
- Automatic save/load
- CloudKit sync support

### Scene Management
- `BaseGameScene`: Base class for all scenes
- `SceneManager`: Handles transitions
- Each location is a separate scene

### Systems

#### Audio System
- Background music
- Sound effects
- Voice-over support
- Volume controls

#### Interaction System
- Touch handling
- Hotspot management
- Gesture recognition

#### Save System
- Local saves with UserDefaults
- CloudKit sync (when online)
- Automatic save on state changes

## Development Guidelines

### Code Organization
- One class/struct per file
- Group related files in folders
- Use MARK comments for navigation

### Naming Conventions
- Classes: `PascalCase`
- Methods/properties: `camelCase`
- Constants: `UPPER_SNAKE_CASE` or `camelCase`
- Files: Match the primary type name

### Access Control
- Use `private` by default
- Use `internal` for module-wide access
- Use `public` only when necessary
- Use `final` for classes not meant to be subclassed

### Best Practices
- Keep scenes under 500 lines
- Extract complex logic to systems
- Use components for reusable behaviors
- Profile memory usage regularly
- For consistent sprite rendering on Simulator and devices, follow Docs/sprite-animation-consistency.md
 - Avoid placing a full grid sprite sheet PNG inside a `.spriteatlas` and slicing via `SKTexture(rect:in:)`. On devices, atlas repacking can break frame order. Prefer per-frame images in the atlas (see Docs/sprite-animation-consistency.md), or keep the grid PNG outside the atlas if you must slice.

## Performance Targets

- **Frame Rate**: 60 FPS on all devices
- **Scene Load**: <1 second
- **Memory**: <200MB active
- **App Size**: <500MB download

## Testing

```bash
# Run all tests
make test

# Run with coverage
make test-coverage

# UI tests only
make test-ui
```

## Debugging

The project includes debug overlays in development builds:
- FPS counter
- Node count
- Memory usage

## CloudKit Setup

1. Enable CloudKit capability in Xcode
2. Create container: `iCloud.com.yourcompany.fishpuzzles`
3. Configure record types for saves

## App Store Preparation

```bash
# Create archive
make archive

# Run final checks
make release-check
```

## Contributing

1. Create feature branch
2. Make changes
3. Run tests
4. Submit PR

## License

Copyright © 2024. All rights reserved.
