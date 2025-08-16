# 🐠 Fish Puzzles

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

Copyright © 2025 Fish Puzzles Team. All rights reserved.

## Support

For questions or issues, please contact the development team or create an issue in the repository.
