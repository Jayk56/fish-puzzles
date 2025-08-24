# Fish Puzzles - Architecture Documentation

Note: The current implementation is a single Xcode project (no SwiftPM multi-module). Some sections below describe the target design and CI/CD pipeline for future modularization and automation. Where there is any mismatch, prefer the in-repo code layout under `fish-puzzles/fish-puzzles/`.

## Overview

Fish Puzzles is a native iOS kid-friendly point-and-click adventure game built with SpriteKit. This architecture prioritizes child safety, performance, and maintainability while delivering a delightful experience for children aged 4-9.

## Quick Start

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ SDK
- macOS Ventura or later
- Apple Developer Account

### Initial Setup
```bash
# Clone repository
git clone https://github.com/yourteam/fish-puzzles.git
cd fish-puzzles

# Install dependencies
make setup

# Generate assets
make atlases

# Build and run
make run
```

## Architecture Documentation

### Core Documents
1. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Complete system architecture overview
2. **[MODULES.md](./MODULES.md)** - Detailed module specifications and dependencies
3. **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** - Project organization and scaffolding
4. **[DATA_FLOW_STATE.md](./DATA_FLOW_STATE.md)** - State management and data flow patterns

### Architecture Decision Records (ADRs)
1. **[ADR-001](./adr/ADR-001-native-ios-spritekit.md)** - Native iOS with SpriteKit
2. **[ADR-002](./adr/ADR-002-ecs-game-objects.md)** - Entity-Component System
3. **[ADR-003](./adr/ADR-003-offline-first-saves.md)** - Offline-first save system
4. **[ADR-004](./adr/ADR-004-privacy-first-analytics.md)** - Privacy-first analytics
5. **[ADR-005](./adr/ADR-005-asset-pipeline.md)** - Asset pipeline and memory management

## Key Architecture Decisions Summary

### Technology Stack
- **Framework**: SpriteKit (native iOS)
- **Language**: Swift 5.9+
- **Minimum iOS**: 16.0
- **Architecture Pattern**: ECS + Unidirectional Data Flow
- **State Management**: Centralized State Manager with Actions
- **Persistence**: CoreData + CloudKit
- **Analytics**: Custom privacy-first implementation

### Design Principles
1. **Child Safety First** - No external connections, parental gates, COPPA compliant
2. **Performance Excellence** - 60 FPS, <200MB memory, <1s scene loads
3. **Offline-First** - Full functionality without internet
4. **Accessibility Native** - VoiceOver, Dynamic Type, high contrast support

## Development Workflow

### Creating New Features

#### 1. New Scene
```bash
./Scripts/create_scene.sh OceanCave
# Creates:
# - Modules/SceneManagement/Sources/Scenes/OceanCaveScene.swift
# - Modules/SceneManagement/Tests/OceanCaveSceneTests.swift
```

#### 2. New Component
```bash
./Scripts/create_component.sh Swimmable
# Creates component from template with proper ECS structure
```

#### 3. New Module
```bash
./Scripts/create_module.sh MiniGames
# Creates complete module structure with Package.swift
```

### Code Standards

#### Swift Style
- SwiftLint enforced
- 100-character line limit
- Explicit self in closures
- Documentation comments for public APIs

#### Testing Requirements
- Minimum 80% code coverage
- Unit tests for all business logic
- UI tests for critical flows
- Performance tests for resource loading

## Performance Targets

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Frame Rate | 60 FPS | CADisplayLink monitoring |
| Scene Load | <1 second | Timer from tap to interactive |
| Memory Usage | <200MB | Instruments profiler |
| Battery Drain | <5%/30min | Energy impact gauge |
| App Size | <500MB | App thinning enabled |

## Security & Privacy

### Data Protection
- No PII collection
- Anonymous device ID only
- CloudKit private database
- Encrypted local saves

### Kids Category Compliance
- COPPA compliant
- No third-party tracking
- Parental gates on external actions
- No social features

## Build Configurations

### Debug
```bash
make debug
# Features: Full logging, debug overlay, memory debugger
```

### Staging
```bash
make staging
# Features: TestFlight ready, crash reporting, limited logging
```

### Release
```bash
make release
# Features: Optimized, minimal logging, App Store ready
```

## Module Dependencies

```
App → GameCore → SceneManagement → AssetPipeline
                ↓                  ↓
         InteractionSystem    AudioSystem
                ↓                  ↓
         InventorySystem      SaveSystem
                               ↓
                           CloudKit
```

## CI/CD Pipeline

### Automated Checks
1. SwiftLint validation
2. Unit test suite (>80% coverage)
3. UI test suite
4. Performance benchmarks
5. Memory leak detection
6. Asset optimization verification

### Deployment
1. Feature branch → PR
2. Two reviewer approval
3. Merge to develop
4. Automatic TestFlight build
5. QA validation
6. Release branch → App Store

## Monitoring & Analytics

### Performance Monitoring
- Frame drops tracking
- Scene load times
- Memory pressure events
- Crash reporting (anonymized)

### Gameplay Metrics (Anonymous)
- Scene completion rates
- Puzzle solve times (bucketed)
- Hint usage frequency
- Settings preferences

## Future Considerations

### Planned Enhancements
- Additional chapters/scenes
- Seasonal content updates
- Achievement system
- Multi-language voice-over

### Technical Debt Management
- Quarterly refactoring sprints
- Dependency updates
- Performance optimization passes
- Accessibility improvements

## Team Resources

### Documentation
- [Design Guide](../design/) - Art and audio specifications
- [QA Test Plans](../tests/) - Testing procedures

### Tools
- [Texture Packer](https://www.codeandweb.com/texturepacker) - Atlas generation
- [Instruments](https://developer.apple.com/instruments/) - Performance profiling
- [Reality Composer](https://developer.apple.com/reality-composer/) - Future AR features

## Getting Help

### Internal Resources
- Slack: #fish-puzzles-dev
- Wiki: Internal documentation
- JIRA: Project tracking

### External Resources
- [SpriteKit Documentation](https://developer.apple.com/spritekit/)
- [App Store Kids Apps](https://developer.apple.com/app-store/kids-apps/)
- [COPPA Compliance](https://www.ftc.gov/tips-advice/business-center/privacy-and-security/children%27s-privacy)

## License

Copyright © 2024 Fish Puzzles Team. All rights reserved.

---

*Last Updated: January 2025*
*Architecture Version: 1.0.0*
