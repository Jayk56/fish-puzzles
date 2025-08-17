# ADR-008: UI Overlay System Architecture

## Status
Accepted

## Context
The game requires multiple UI overlays that can appear over the main gameplay:
- Inventory for item management
- Map for navigation overview
- Hint system for puzzle assistance
- Sound controls for audio settings
- Settings for game preferences
- Dialogue boxes for character conversations

These overlays must coexist without interfering with gameplay or each other.

## Decision
Implement a layered UI overlay system with:
1. **HUDManager**: Central coordinator for all overlays
2. **Layer priorities**: Z-ordered overlay stacking
3. **Modal states**: Control touch passthrough
4. **Transition system**: Smooth show/hide animations

## Architecture

```swift
// HUDManager.swift
class HUDManager {
    enum OverlayType: Int {
        case gameWorld = 0      // Base game layer
        case hud = 100          // Always-visible HUD elements
        case inventory = 200    // Inventory overlay
        case map = 201          // Map overlay  
        case dialogue = 300     // Dialogue boxes
        case hint = 400         // Hint popups
        case settings = 500     // Settings menu
        case pause = 600        // Pause overlay
    }
    
    private var overlays: [OverlayType: UIOverlay] = [:]
    private var activeOverlays: Set<OverlayType> = []
    
    func show(_ type: OverlayType, animated: Bool = true)
    func hide(_ type: OverlayType, animated: Bool = true)
    func toggle(_ type: OverlayType)
    func hideAll(except: [OverlayType] = [])
}

// Base overlay protocol
protocol UIOverlay {
    var layer: OverlayType { get }
    var isModal: Bool { get }  // Blocks touches to lower layers
    var dimBackground: Bool { get }
    
    func show(animated: Bool)
    func hide(animated: Bool)
    func update(deltaTime: TimeInterval)
}
```

## Overlay Components

### 1. Inventory Overlay
```swift
class InventoryOverlay: SKNode, UIOverlay {
    // Grid-based item slots
    // Drag-and-drop support
    // Item combination detection
    // Scrollable for many items
}
```

### 2. Map Overlay
```swift
class MapOverlay: SKNode, UIOverlay {
    // Scene thumbnail previews
    // Current location indicator
    // Discovered/undiscovered areas
    // Fast travel (if unlocked)
}
```

### 3. Hint System
```swift
class HintOverlay: SKNode, UIOverlay {
    enum HintLevel {
        case subtle     // "Maybe I should look around more"
        case moderate   // "That item might be useful"
        case explicit   // "Use the key on the door"
    }
    
    // Progressive hint revealing
    // Cooldown between hints
    // Context-aware suggestions
}
```

### 4. Sound Controls
```swift
class SoundOverlay: SKNode, UIOverlay {
    // Master volume slider
    // Music volume slider
    // SFX volume slider
    // Voice-over toggle
    // Subtitles toggle
}
```

### 5. Settings Overlay
```swift
class SettingsOverlay: SKNode, UIOverlay {
    // Text size options
    // Colorblind modes
    // Reduced motion toggle
    // Parental controls
    // Credits/about
}
```

## Touch Handling

```swift
extension HUDManager {
    func handleTouch(at point: CGPoint) -> Bool {
        // Check overlays from highest to lowest priority
        let sortedOverlays = activeOverlays.sorted { $0.rawValue > $1.rawValue }
        
        for overlayType in sortedOverlays {
            guard let overlay = overlays[overlayType] else { continue }
            
            if overlay.contains(point) {
                overlay.handleTouch(at: point)
                return !overlay.isModal  // Stop propagation if modal
            }
        }
        return false  // Touch not handled
    }
}
```

## Visual Design Guidelines

### Layer Organization
```
Z-Index    Layer              Description
-------    -----              -----------
600+       Pause              Full screen pause menu
500-599    Settings           Settings and options
400-499    Hints              Hint bubbles and tutorials  
300-399    Dialogue           Character speech bubbles
200-299    Overlays           Inventory, map screens
100-199    HUD                Persistent UI elements
0-99       Game World         Main gameplay layer
```

### Safe Area Handling
```swift
struct SafeAreaManager {
    // Account for notches and home indicators
    // Adjust overlay positions for device
    // Maintain touch target sizes (44pt minimum)
}
```

## Consequences

### Positive
- **Clear hierarchy**: Well-defined layer system prevents conflicts
- **Modular design**: Easy to add new overlay types
- **Consistent UX**: Unified animation and interaction patterns
- **Performance**: Only active overlays consume resources
- **Accessibility**: Centralized control for screen readers

### Negative
- **Complexity**: Multiple systems to coordinate
- **Memory usage**: Many overlays loaded simultaneously
- **Testing burden**: Many overlay combinations to test
- **Learning curve**: Designers must understand layer system

### Risks
- **Touch conflicts**: Overlapping touch areas between layers
- **Performance impact**: Too many active overlays affecting FPS

## Alternatives Considered

1. **Single modal system**: One overlay at a time
   - Rejected: Too limiting for complex UI needs

2. **UIKit overlays**: Native iOS views over SpriteKit
   - Rejected: Harder to integrate with game rendering

3. **Scene transitions**: Separate scenes for each overlay
   - Rejected: Expensive transitions, loses game state

4. **SwiftUI integration**: Modern UI framework
   - Rejected: Complex SpriteKit integration, requires iOS 16+

## Implementation Priority
1. HUD elements (always visible)
2. Inventory system (core gameplay)
3. Dialogue system (story progression)
4. Settings/sound (user preferences)
5. Map overlay (navigation aid)
6. Hint system (accessibility)

## References
- [Apple HIG - Modality](https://developer.apple.com/design/human-interface-guidelines/modality)
- [Game UI Patterns](https://gameuipatterns.com/)
- [Designing Game UI for Kids](https://www.nngroup.com/articles/childrens-games/)