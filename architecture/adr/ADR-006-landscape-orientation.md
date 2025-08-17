# ADR-006: Landscape-Only Orientation

## Status
Accepted

## Context
The game targets young children aged 4-9 who will primarily play on iPads and iPhones. We need to decide on the optimal screen orientation that:
- Provides the best viewport for exploration gameplay
- Matches natural device holding patterns for children
- Maximizes screen real estate for interactive elements
- Ensures consistent experience across all devices

## Decision
The game will launch and play exclusively in landscape orientation with:
- Device rotated 90° counter-clockwise (landscape-right)
- Top of phone on the right side
- Bottom of phone (home indicator) on the left side
- No orientation changes during gameplay

## Implementation
```swift
// GameViewController.swift
override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .landscapeRight
}

override var shouldAutorotate: Bool {
    return false
}

// Info.plist
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

## Consequences

### Positive
- **Wider viewport**: Better for side-scrolling exploration and scene navigation
- **Natural grip**: Children can hold device with both hands comfortably
- **UI placement**: More room for inventory bar and interaction buttons
- **Consistent layout**: No need to handle orientation changes mid-game
- **Performance**: Single orientation reduces layout recalculation overhead
- **Art optimization**: Artists can optimize for one aspect ratio

### Negative
- **Single orientation**: Users can't rotate to their preference
- **Home indicator**: Always visible on left side (iOS limitation)
- **Initial rotation**: Users must rotate device before play
- **Portrait content**: Any portrait-oriented content needs redesign

### Risks
- **User confusion**: Some users expect portrait for mobile games
- **Accessibility**: Some motor-impaired users may prefer portrait

## Alternatives Considered

1. **Portrait orientation**: Traditional mobile game orientation
   - Rejected: Limited horizontal space for exploration scenes

2. **Both landscape orientations**: Allow landscape-left and landscape-right
   - Rejected: UI elements would flip unexpectedly for young users

3. **All orientations**: Full rotation support
   - Rejected: Complex UI adaptation, confusing for target age group

4. **Adaptive orientation**: Different orientations for different screens
   - Rejected: Inconsistent experience, development complexity

## Mitigation Strategies
- Clear visual prompt on launch to rotate device
- Lock orientation early in app lifecycle
- Design UI elements to avoid home indicator area

## References
- [Apple Human Interface Guidelines - Orientation](https://developer.apple.com/design/human-interface-guidelines/orientation)
- [iOS Orientation Best Practices](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621435-supportedinterfaceorientations)