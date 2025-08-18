# ADR-011: Touch Interaction Patterns for Kids

## Status
Proposed

## Context
Point-and-click adventure games traditionally use mouse-based interactions with hover states and right-click menus. Translating these patterns to touch interfaces for young children (ages 4-9) requires careful consideration of:

- Motor skill development varies significantly in this age range
- Touch targets need to be larger than adult standards
- Multi-touch gestures are difficult for young children
- Feedback must be immediate and clear
- Accidental touches are common

Research shows that children in our target age group:
- Prefer direct manipulation over abstract controls
- Need visual feedback for every interaction
- Struggle with timing-based gestures (long press)
- Have difficulty with precise targeting

## Decision
Implement a child-friendly touch interaction system prioritizing simplicity, forgiveness, and clear feedback.

### Core Principles
1. **Single touch primary**: All core actions achievable with single touches
2. **Large touch targets**: Minimum 60pt (vs Apple's 44pt standard)
3. **Immediate feedback**: Visual/audio response within 100ms
4. **Forgiving interactions**: Undo/cancel readily available
5. **Progressive complexity**: Advanced gestures optional

## Interaction Patterns

### Primary Actions

#### Tap-to-Move Character
```swift
struct TapToMoveSystem {
    // Visual feedback for movement
    func showMoveTarget(at point: CGPoint) {
        // Ripple animation at tap point
        // Footstep trail from character to target
        // Character orientation toward target
    }
    
    // Cancellation
    func cancelMovement() {
        // New tap cancels current movement
        // No penalty for changing mind
    }
    
    // Pathfinding
    func calculatePath(from: CGPoint, to: CGPoint) -> [CGPoint] {
        // Simple obstacle avoidance
        // Smooth curved paths (not straight lines)
        // Automatic navigation around objects
    }
}
```

#### Touch States
```swift
enum TouchInteractionState {
    case idle
    case touching(location: CGPoint, duration: TimeInterval)
    case moving(from: CGPoint, to: CGPoint, velocity: CGVector)
    case ended(location: CGPoint, duration: TimeInterval)
    
    var requiresConfirmation: Bool {
        // Destructive actions need confirmation
        switch self {
        case .ended(_, let duration) where duration > 0.5:
            return true  // Long press might be accidental
        default:
            return false
        }
    }
}
```

### Interaction Zones
```swift
struct InteractionZone {
    let bounds: CGRect
    let expandedBounds: CGRect  // Larger hit area for forgiveness
    let priority: Int  // Resolve overlapping zones
    
    static func minimumSize(for age: Int) -> CGSize {
        switch age {
        case 4...5: return CGSize(width: 80, height: 80)
        case 6...7: return CGSize(width: 60, height: 60)
        case 8...9: return CGSize(width: 50, height: 50)
        default: return CGSize(width: 44, height: 44)
        }
    }
}
```

## Context-Sensitive Feedback

### Visual Indicators
```swift
enum InteractionType {
    case look       // Eye icon - examine object
    case take       // Hand icon - pick up item
    case use        // Gear icon - interact with
    case talk       // Speech bubble - dialogue
    case move       // Footsteps - walk here
    case blocked    // X icon - can't do that
    
    var icon: String {
        switch self {
        case .look: return "👁"
        case .take: return "✋"
        case .use: return "⚙️"
        case .talk: return "💬"
        case .move: return "👣"
        case .blocked: return "❌"
        }
    }
    
    var color: UIColor {
        switch self {
        case .look: return .systemBlue
        case .take: return .systemGreen
        case .use: return .systemOrange
        case .talk: return .systemPurple
        case .move: return .systemGray
        case .blocked: return .systemRed
        }
    }
}
```

### Hotspot Highlighting
```swift
class HotspotHighlightSystem {
    enum HighlightLevel {
        case subtle     // Slight glow, shown on proximity
        case moderate   // Pulsing glow, shown on focus
        case strong     // Bright outline, shown on interaction
    }
    
    func updateHighlights(touchLocation: CGPoint) {
        // Distance-based highlighting
        for hotspot in nearbyHotspots(to: touchLocation) {
            let distance = hotspot.distance(to: touchLocation)
            
            if distance < 50 {
                hotspot.highlight(.strong)
            } else if distance < 100 {
                hotspot.highlight(.moderate)
            } else if distance < 150 {
                hotspot.highlight(.subtle)
            }
        }
    }
}
```

## Gesture Recognition

### Supported Gestures
```swift
struct KidFriendlyGestureRecognizer {
    // Primary gestures (always available)
    let tap = UITapGestureRecognizer()           // Single tap only
    let pan = UIPanGestureRecognizer()           // For dragging items
    
    // Secondary gestures (optional/assistive)
    let longPress = UILongPressGestureRecognizer(
        target: nil,
        action: nil
    ).then {
        $0.minimumPressDuration = 1.0  // Longer than adult standard
    }
    
    // Explicitly disabled gestures
    // - No pinch (zoom)
    // - No rotation
    // - No multi-finger gestures
    // - No force touch
    // - No double tap (too fast for young kids)
}
```

### Drag and Drop
```swift
class KidFriendlyDragDrop {
    struct Configuration {
        let dragThreshold: CGFloat = 15  // Larger than adult standard
        let snapDistance: CGFloat = 30   // Generous snap-to-target
        let cancelDistance: CGFloat = 200  // Drag far to cancel
        
        let dragFeedback = DragFeedback(
            scale: 1.2,           // Make dragged item bigger
            opacity: 0.8,         // Slightly transparent
            shadow: true,         // Drop shadow for depth
            wiggle: true          // Gentle rotation animation
        )
    }
    
    func handleDrag(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            // Haptic feedback
            // Scale up animation
            // Lift shadow effect
            
        case .changed:
            // Follow finger with offset
            // Highlight valid drop targets
            // Show preview of action
            
        case .ended:
            if let target = validDropTarget(at: gesture.location) {
                // Snap to target
                // Execute action
                // Success feedback
            } else {
                // Animate back to origin
                // Cancel feedback
            }
        }
    }
}
```

## Accessibility Features

### One-Touch Mode
```swift
class OneTouchAccessibility {
    // Everything achievable with single taps
    enum Action {
        case select     // First tap selects
        case confirm    // Second tap confirms
        case cancel     // Tap elsewhere cancels
    }
    
    // Visual confirmation of selection
    func showSelection(for element: SKNode) {
        // Highlight border
        // Show action menu
        // Voice over description
    }
    
    // Simplified interactions
    var simplifiedDragDrop = false  // Tap source, tap destination
    var autoTarget = true            // Snap to nearest valid target
    var confirmDestructive = true    // Always confirm deletions
}
```

### Touch Adjustment
```swift
struct TouchAdjustment {
    // Compensate for finger occlusion
    static func adjustedPoint(
        for touch: UITouch,
        in view: SKView
    ) -> CGPoint {
        let rawPoint = touch.location(in: view)
        
        // Offset touch point above finger
        let offset = CGPoint(x: 0, y: -20)
        
        // Apply adjustment based on touch radius
        let radius = touch.majorRadius
        let adjustmentFactor = min(radius / 30, 1.0)
        
        return CGPoint(
            x: rawPoint.x + offset.x * adjustmentFactor,
            y: rawPoint.y + offset.y * adjustmentFactor
        )
    }
}
```

## Error Prevention

### Accidental Touch Prevention
```swift
class AccidentalTouchPrevention {
    // Ignore edges where holding occurs
    let edgeDeadZone: CGFloat = 20
    
    // Require deliberate interaction
    let minimumTouchDuration: TimeInterval = 0.1
    let maximumTouchVelocity: CGFloat = 500
    
    // Undo system
    let undoManager = UndoManager().then {
        $0.levelsOfUndo = 10
        $0.groupsByEvent = true
    }
    
    func validateTouch(_ touch: UITouch) -> Bool {
        // Check if touch is deliberate
        guard !isNearEdge(touch.location),
              touch.force < touch.maximumPossibleForce * 0.8,
              touchVelocity < maximumTouchVelocity else {
            return false
        }
        return true
    }
}
```

## Consequences

### Positive
- **Age-appropriate**: Matches motor skills of target age
- **Forgiving**: Reduces frustration from mistakes
- **Discoverable**: Visual feedback guides learning
- **Accessible**: Works for various ability levels
- **Intuitive**: Leverages familiar mobile patterns

### Negative
- **Slower pace**: Larger targets mean less content visible
- **Limited complexity**: Can't use advanced gestures
- **More animations**: Feedback systems increase complexity
- **Screen space**: Larger UI elements reduce game area

## Alternatives Considered

1. **Virtual Joystick**
   - Rejected: Abstract control, occludes screen

2. **Gesture-Based Navigation**
   - Rejected: Too complex for young children

3. **Tilt Controls**
   - Rejected: Requires steady hands, tiring

4. **Voice Commands**
   - Rejected: Not reliable, privacy concerns

5. **Mouse-Like Cursor**
   - Rejected: Indirect manipulation confusing for kids

## Implementation Priority
1. Basic tap-to-move system
2. Touch target sizing system
3. Visual feedback for all interactions
4. Hotspot highlighting
5. Drag and drop with snap-to-target
6. One-touch accessibility mode
7. Undo/redo system

## Testing Requirements
- Test with actual children in age range
- Measure touch accuracy rates
- Track error/retry frequencies
- Monitor frustration indicators
- Validate with accessibility guidelines

## References
- [Designing for Kids: Cognitive Considerations](https://www.nngroup.com/articles/kids-cognition/)
- [Touch Interaction for Toddlers](https://www.lukew.com/ff/entry.asp?1197)
- [Apple HIG - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [WCAG 2.1 - Target Size](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html)