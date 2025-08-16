# Fish Puzzles - iOS Architecture Documentation

## Executive Summary

Fish Puzzles is a kid-friendly point-and-click adventure game built natively for iOS using SpriteKit and Swift. The architecture prioritizes safety, performance, and maintainability while delivering a delightful experience for children aged 4-9.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        App Layer                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │  AppDel  │ │  Scene   │ │   Root   │ │ Settings │      │
│  │  egate   │ │  Coord   │ │   VC     │ │    VC    │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Game Core Layer                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │  Scene   │ │  Game    │ │ Interact │ │Inventory │      │
│  │  Manager │ │  State   │ │  System  │ │  System  │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Services Layer                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │  Audio   │ │   Save   │ │  Asset   │ │Analytics │      │
│  │  Manager │ │  System  │ │  Loader  │ │ (Safe)   │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Foundation Layer                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │ CloudKit │ │  Local   │ │  Cache   │ │  Logger  │      │
│  │  Sync    │ │  Storage │ │  Manager │ │          │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Core Design Principles

### 1. Child Safety First
- No external network calls except CloudKit
- All content pre-validated and bundled
- Parental gates on all external actions
- No user-generated content

### 2. Performance Excellence
- 60 FPS on all supported devices
- Memory budget: <200MB active
- Lazy loading with intelligent prefetch
- Efficient sprite atlasing

### 3. Offline-First Design
- Full gameplay without internet
- CloudKit sync when available
- Local save with conflict resolution
- Graceful degradation

### 4. Accessibility Native
- VoiceOver support throughout
- Dynamic type support
- High contrast mode
- Reduced motion options

## Architecture Patterns

### Scene-Based Game Flow
```swift
protocol GameScene {
    var sceneID: String { get }
    var nextScenes: [String] { get }
    func didEnterScene()
    func willExitScene()
    func handleInteraction(at point: CGPoint)
}
```

### Entity-Component System (ECS)
```swift
protocol Component {
    var entity: Entity? { get set }
}

class Entity {
    private var components: [String: Component] = [:]
    
    func add<T: Component>(_ component: T)
    func get<T: Component>(_ type: T.Type) -> T?
    func remove<T: Component>(_ type: T.Type)
}
```

### State Machine Pattern
```swift
enum GameState {
    case mainMenu
    case playing(location: LocationID)
    case paused
    case inventory
    case dialogue(character: CharacterID)
    case cutscene(id: String)
}
```

## Module Architecture

### 1. Scene Management Module
- **Responsibility**: Scene lifecycle, transitions, memory management
- **Key Classes**: `SceneCoordinator`, `SceneFactory`, `TransitionManager`
- **Dependencies**: SpriteKit, GameCore

### 2. Interaction System Module  
- **Responsibility**: Touch handling, hotspot detection, gesture recognition
- **Key Classes**: `InteractionManager`, `Hotspot`, `GestureHandler`
- **Dependencies**: UIKit, SpriteKit

### 3. Inventory System Module
- **Responsibility**: Item management, combination logic, UI presentation
- **Key Classes**: `InventoryManager`, `Item`, `InventoryUI`
- **Dependencies**: GameCore, UIKit

### 4. Audio System Module
- **Responsibility**: Music, VO, SFX playback and mixing
- **Key Classes**: `AudioManager`, `VoiceOverPlayer`, `MusicController`
- **Dependencies**: AVFoundation, CoreAudio

### 5. Save System Module
- **Responsibility**: Game state persistence, CloudKit sync
- **Key Classes**: `SaveManager`, `CloudSyncService`, `SaveState`
- **Dependencies**: CloudKit, CoreData

### 6. Asset Pipeline Module
- **Responsibility**: Resource loading, caching, memory management
- **Key Classes**: `AssetLoader`, `TextureCache`, `AssetBundle`
- **Dependencies**: Foundation, SpriteKit

### 7. Analytics Module (Privacy-Safe)
- **Responsibility**: Anonymous gameplay metrics
- **Key Classes**: `AnalyticsManager`, `Event`, `PrivacyGuard`
- **Dependencies**: None (custom implementation)

### 8. Localization Module
- **Responsibility**: String management, RTL support, VO mapping
- **Key Classes**: `LocalizationManager`, `StringTable`, `VOMapper`
- **Dependencies**: Foundation

## Data Flow Architecture

```
User Input → Interaction System → Game State → Scene Update → Render
                    ↓                  ↓            ↓
              Haptic Feedback    Save System   Audio System
```

## Memory Management Strategy

### Texture Atlasing
- Location-based atlases (1 per scene)
- Character sheets (shared across scenes)
- UI atlas (persistent)
- Maximum atlas size: 2048x2048

### Resource Loading
```swift
class ResourceManager {
    // Preload next scene while current plays
    func preloadScene(_ sceneID: String)
    
    // Unload scenes beyond 1-back buffer
    func pruneUnusedResources()
    
    // Emergency memory pressure response
    func handleMemoryWarning()
}
```

## Error Handling Philosophy

### Kid-Friendly Failures
- Never crash or show technical errors
- Graceful fallbacks for all failures
- Parent-accessible error logs
- Auto-recovery where possible

```swift
enum GameError: Error {
    case assetMissing(String)
    case saveFailed(Error)
    case audioPlaybackFailed(Error)
    
    var kidFriendlyMessage: String {
        // Always return safe, non-technical message
    }
}
```

## Security & Privacy Architecture

### Data Protection
- No PII collection
- Anonymous device ID only
- All saves encrypted at rest
- CloudKit private database only

### Parental Controls
```swift
class ParentalGate {
    static func present(for action: ExternalAction, 
                       completion: (Bool) -> Void)
    
    enum ExternalAction {
        case openWebLink(URL)
        case rateApp
        case shareContent
        case accessSettings
    }
}
```

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|------------|
| Frame Rate | 60 FPS | CADisplayLink |
| Scene Load | <1s | From tap to interactive |
| Memory | <200MB | Active footprint |
| Battery | <5% drain | 30 min session |
| Download Size | <500MB | App thinning enabled |

## Testing Architecture

### Unit Testing
- Business logic isolation
- Mock scene framework
- Interaction verification

### UI Testing
- XCUITest for flows
- Snapshot testing for scenes
- Accessibility audits

### Performance Testing
- XCTest metrics
- Instruments profiling
- Device matrix testing

## Build & Deployment

### Build Configuration
```
Debug: Full logging, debug overlay, skip parental gate
Staging: TestFlight ready, analytics enabled
Release: App Store optimized, minimal logging
```

### CI/CD Pipeline
1. Code commit triggers build
2. Unit tests run
3. UI tests on simulators
4. Performance benchmarks
5. TestFlight upload (staging)
6. Automated smoke tests
7. Stakeholder notification

## Monitoring & Observability

### Crash Reporting
- MetricKit integration
- Symbolicated crash logs
- Parent-accessible diagnostics

### Performance Monitoring
```swift
class PerformanceMonitor {
    func trackSceneLoad(_ scene: String, duration: TimeInterval)
    func trackMemoryPressure(level: MemoryPressureLevel)
    func trackFrameDrops(count: Int, scene: String)
}
```

## Platform-Specific Considerations

### iOS vs iPadOS
- Adaptive layouts using size classes
- iPad-specific UI enhancements
- Multitasking support (Slide Over)
- Keyboard support for iPad

### Device Variants
- iPhone SE to Pro Max support
- iPad mini to Pro support
- Dynamic island awareness
- Safe area management

## Future Architecture Considerations

### Extensibility Points
- Additional scenes via DLC
- New puzzle types
- Seasonal content
- Achievement system

### Technical Debt Management
- Quarterly refactoring sprints
- Dependency updates
- Performance optimization passes
- Accessibility improvements

## Architecture Governance

### Code Review Standards
- All PRs require 2 reviewers
- Performance impact assessment
- Memory profiling for new scenes
- Accessibility checklist

### Documentation Requirements
- ADRs for significant changes
- API documentation (DocC)
- Scene flow diagrams
- Component interaction docs