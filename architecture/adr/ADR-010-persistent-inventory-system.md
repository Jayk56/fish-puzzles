# ADR-010: Persistent Inventory System

## Status
Proposed

## Context
The current inventory system uses a modal overlay that covers the game screen when opened. This creates friction for young players (ages 4-9) who need to frequently access and use items during puzzle-solving. Children in this age range benefit from immediate visual feedback and struggle with abstract modal states.

User testing insights for this age group suggest:
- Children often forget what items they have if not visible
- Modal overlays can be confusing (losing game context)
- Drag-and-drop is more intuitive than multi-step selection
- Visual persistence helps with problem-solving

## Decision
Implement a persistent, always-visible inventory bar with quick-access slots instead of a modal inventory screen.

### Core Design
- **Always-visible inventory bar** at bottom of screen
- **4-6 quick slots** for immediate access
- **Selected item highlighting** with visual feedback
- **Overflow handling** via expandable drawer or pagination
- **Drag-and-drop** as primary interaction method

## Architecture

### Component Structure
```swift
class PersistentInventoryBar: SKNode {
    // Configuration
    static let maxVisibleSlots = 5
    static let slotSize = CGSize(width: 80, height: 80)
    
    // State management
    private var visibleSlots: [InventorySlot] = []
    private var selectedSlot: InventorySlot?
    private var overflowItems: [Item] = []
    
    // Visual components
    private let backgroundBar: SKShapeNode
    private let moreButton: HUDButton?
    private let selectedIndicator: SKEffectNode
}
```

### Inventory Slot Design
```swift
class InventorySlot: SKNode {
    enum State {
        case empty
        case occupied(item: Item)
        case selected(item: Item)
        case dragging(item: Item)
    }
    
    var state: State = .empty
    let position: Int  // 0-based index in bar
    
    // Visual feedback
    func highlight(animated: Bool)
    func dim(animated: Bool)
    func showValidDropTarget()
    func showInvalidDropTarget()
}
```

### Interaction Flow
```swift
protocol InventoryInteractionDelegate {
    func didSelectItem(_ item: Item)
    func didDeselectItem(_ item: Item)
    func canUseItem(_ item: Item, on target: Entity) -> Bool
    func useItem(_ item: Item, on target: Entity)
    func canCombineItems(_ item1: Item, _ item2: Item) -> Bool
    func combineItems(_ item1: Item, _ item2: Item) -> Item?
}
```

## Visual Design

### Layout Specifications
```
Screen Layout (Landscape):
┌─────────────────────────────────────────────┐
│                                             │
│              Game World                     │
│                                             │
├─────────────────────────────────────────────┤
│ [📦] [🔑] [🍎] [🔨] [📜] [+3]              │ ← Inventory Bar
└─────────────────────────────────────────────┘
   ↑    ↑    ↑    ↑    ↑    ↑
 Slot1 Slot2 Slot3 Slot4 Slot5 More
```

### Visual States
1. **Normal**: Item at rest, subtle drop shadow
2. **Selected**: Glowing border, slight scale increase (1.1x)
3. **Dragging**: Semi-transparent, follows touch
4. **Valid Target**: Green glow on target object
5. **Invalid Target**: Red pulse, shake animation

### Safe Area Considerations
```swift
struct InventoryBarLayout {
    // Account for device safe areas
    static func calculateBarFrame(for size: CGSize) -> CGRect {
        let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
        let barHeight: CGFloat = 100
        
        return CGRect(
            x: safeAreaInsets.left,
            y: safeAreaInsets.bottom,
            width: size.width - safeAreaInsets.left - safeAreaInsets.right,
            height: barHeight
        )
    }
}
```

## Interaction Patterns

### Primary Interactions
1. **Tap to Select**
   - Single tap selects item
   - Selected item shows cursor attachment
   - Tap in world uses selected item

2. **Drag and Drop**
   - Long press initiates drag
   - Visual feedback during drag
   - Drop on valid targets triggers use

3. **Item Combination**
   - Drag one item onto another
   - Preview combination result
   - Confirm with release

### Accessibility Mode
```swift
struct AccessibilityInventoryMode {
    // One-touch mode for motor impairments
    enum InteractionMode {
        case standard     // Drag and drop
        case simplified   // Tap to select, tap to use
        case assisted     // Voice control compatible
    }
    
    // Adjustable timing
    var longPressThreshold: TimeInterval = 0.5
    var dragThreshold: CGFloat = 10.0
}
```

## Overflow Handling

### Strategies for Many Items
1. **Pagination Dots**
   - Swipe left/right to see more items
   - Page indicators show position

2. **Expandable Drawer**
   - "More" button opens mini-grid
   - Recent items prioritized in quick slots

3. **Auto-Organization**
   - Most recently used items in visible slots
   - Quest-critical items prioritized

## Consequences

### Positive
- **Always visible**: Kids never lose track of inventory
- **Faster interaction**: No modal open/close overhead
- **Context preserved**: Game world remains visible
- **Intuitive**: Matches mobile app patterns kids know
- **Discoverable**: Items immediately visible when collected

### Negative
- **Screen space**: Reduces available game viewport
- **Limited slots**: Only 4-6 items immediately accessible
- **Complexity**: More complex than modal approach
- **Touch conflicts**: Potential accidental inventory touches

### Mitigation Strategies
- **Smart hiding**: Auto-hide during cutscenes/dialogue
- **Gesture lock**: Require deliberate interaction to prevent accidents
- **Visual hierarchy**: Ensure game world remains focus

## Alternatives Considered

1. **Modal Inventory (Current)**
   - Rejected: Too disruptive for young players
   
2. **Radial Menu**
   - Rejected: Harder for kids to navigate precisely

3. **Side Panel Drawer**
   - Rejected: Landscape orientation makes sides less accessible

4. **Floating Inventory Bubbles**
   - Rejected: Clutters game world, blocks content

5. **Context-Sensitive Items Only**
   - Rejected: Limits puzzle design flexibility

## Implementation Priority
1. Basic persistent bar with 5 slots
2. Tap to select/use mechanics
3. Visual feedback system
4. Drag and drop support
5. Overflow handling
6. Accessibility features
7. Auto-organization logic

## Testing Considerations
- A/B test with modal inventory for comparison
- Track item usage frequency and patterns
- Monitor accidental touch rates
- Measure time-to-use metrics
- Gather feedback from playtesting with target age group

## References
- [Designing Interfaces for Children](https://www.nngroup.com/articles/childrens-websites-usability-issues/)
- [Touch Interaction Design for Toddlers](https://www.lukew.com/ff/entry.asp?1197)
- [Game UI Patterns - Inventory Systems](https://gameuipatterns.com/gameui/inventory/)
- [Apple HIG - Touch Bar Design](https://developer.apple.com/design/human-interface-guidelines/touch-bar)