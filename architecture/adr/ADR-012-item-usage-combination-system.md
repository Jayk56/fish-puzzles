# ADR-012: Item Usage and Combination System

## Status
Proposed

## Context
Point-and-click adventure games rely heavily on item-based puzzle solving. Players collect items, use them on environment objects, and sometimes combine items to create new ones. For our young audience (ages 4-9), this system must be:

- Immediately understandable without instructions
- Forgiving of experimentation
- Visually clear about what's possible
- Rewarding for both success and logical attempts

Traditional adventure games often frustrate players with:
- Obscure item combinations
- Unclear interaction feedback  
- Pixel hunting for hotspots
- Trial-and-error exhaustion

## Decision
Implement a visually-guided item interaction system that encourages experimentation while preventing frustration through clear feedback and logical constraints.

### Design Principles
1. **Visual affordances**: Show what's possible before attempting
2. **Logical combinations**: Items combine in ways kids expect
3. **Positive feedback**: Celebrate attempts, not just successes
4. **Progressive disclosure**: Complexity increases with game progress
5. **No dead ends**: Can't lose or destroy critical items

## Item System Architecture

### Item Definition
```swift
struct Item: Codable {
    let id: String
    let name: String
    let displayName: String  // Localized, kid-friendly name
    let icon: String         // Texture name for inventory
    let description: String  // Simple description for accessibility
    
    // Interaction properties
    let isCombinable: Bool
    let isConsumable: Bool
    let isKeyItem: Bool     // Can't be discarded
    
    // Visual properties
    let glowColor: UIColor?  // Hint at item type/use
    let particleEffect: String?  // Special effects
    
    // Combination rules
    let combinesWith: [String]  // Item IDs this combines with
    let resultingItem: String?  // Item ID created from combination
}
```

### Interaction Rules Engine
```swift
class ItemInteractionEngine {
    struct InteractionRule {
        let itemID: String
        let targetID: String  // Entity or other item
        let action: InteractionAction
        let result: InteractionResult
        let conditions: [InteractionCondition]
    }
    
    enum InteractionAction {
        case use           // Use item on target
        case combine       // Combine with another item
        case examine       // Look at item closely
        case giveTo        // Give to character
    }
    
    enum InteractionResult {
        case success(effects: [Effect])
        case partial(hint: String, effects: [Effect])
        case invalid(reason: String)
        case funny(message: String)  // Humorous failure
    }
    
    enum InteractionCondition {
        case hasItem(String)
        case locationIs(String)
        case puzzleSolved(String)
        case characterMet(String)
    }
}
```

## Visual Feedback System

### Interaction States
```swift
enum ItemInteractionState {
    case idle
    case selected(item: Item)
    case hovering(item: Item, over: Entity)
    case validTarget(item: Item, target: Entity)
    case invalidTarget(item: Item, target: Entity)
    case combining(item1: Item, item2: Item)
    case using(item: Item, on: Entity)
    
    var cursorAppearance: CursorStyle {
        switch self {
        case .idle:
            return .default
        case .selected(let item):
            return .itemCursor(item.icon)
        case .hovering:
            return .questionMark
        case .validTarget:
            return .checkmark
        case .invalidTarget:
            return .prohibited
        case .combining:
            return .plus
        case .using:
            return .animated(.sparkle)
        }
    }
    
    var targetHighlight: HighlightStyle {
        switch self {
        case .validTarget:
            return .glow(color: .green, intensity: 0.8)
        case .invalidTarget:
            return .pulse(color: .red, rate: 2.0)
        case .hovering:
            return .outline(color: .yellow, width: 2.0)
        default:
            return .none
        }
    }
}
```

### Feedback Animations
```swift
class ItemFeedbackAnimator {
    // Success feedback
    func showSuccess(at point: CGPoint) {
        // Sparkle burst
        // Item merge animation
        // Happy sound effect
        // Optional: Character reaction
    }
    
    // Failure feedback
    func showInvalid(at point: CGPoint, reason: InvalidReason) {
        switch reason {
        case .wrongItem:
            // Gentle shake
            // "Nope" sound
            // Red flash
            
        case .notYet:
            // Lock icon
            // "Too early" sound
            // Gray out effect
            
        case .illogical:
            // Question marks
            // Confused sound
            // Wobble animation
        }
    }
    
    // Near-miss feedback
    func showAlmostCorrect(at point: CGPoint) {
        // Warm glow
        // Encouraging sound
        // Hint particles toward correct target
    }
}
```

## Combination System

### Visual Combination Interface
```swift
class ItemCombinationView: SKNode {
    private let slot1 = CombinationSlot()
    private let slot2 = CombinationSlot()
    private let resultSlot = CombinationSlot()
    private let combineButton = AnimatedButton(text: "Mix!")
    
    func showCombination(item1: Item, item2: Item) {
        // Animate items into slots
        slot1.setItem(item1)
        slot2.setItem(item2)
        
        // Preview result if valid
        if let result = previewCombination(item1, item2) {
            resultSlot.showPreview(result)
            combineButton.enable()
        } else {
            resultSlot.showQuestionMark()
            combineButton.disable()
        }
    }
    
    func animateCombination() {
        // Items spiral together
        // Puff of smoke/sparkles
        // Result appears with fanfare
    }
}
```

### Combination Rules
```swift
struct CombinationDatabase {
    // Logical combinations kids would expect
    static let recipes: [CombinationRecipe] = [
        // Food combinations
        CombinationRecipe(
            inputs: ["peanut_butter", "jelly"],
            output: "pb_j_sandwich",
            animation: .squish
        ),
        
        // Tool combinations
        CombinationRecipe(
            inputs: ["stick", "string"],
            output: "fishing_rod",
            animation: .bind
        ),
        
        // Color mixing (educational)
        CombinationRecipe(
            inputs: ["blue_paint", "yellow_paint"],
            output: "green_paint",
            animation: .swirl
        )
    ]
    
    // Funny failure responses
    static let sillyAttempts: [String: String] = [
        "fish+bicycle": "The fish doesn't know how to ride!",
        "key+soup": "The key gets all soggy!",
        "hat+sandwich": "That's not a lunch box!"
    ]
}
```

## Usage Patterns

### Use Item on World
```swift
class ItemUsageSystem {
    func attemptUse(item: Item, on target: Entity) -> UsageResult {
        // Check if combination is valid
        guard let rule = findRule(item: item, target: target) else {
            return handleInvalidUse(item: item, target: target)
        }
        
        // Check conditions
        for condition in rule.conditions {
            if !condition.isMet() {
                return .blocked(reason: condition.hint)
            }
        }
        
        // Execute interaction
        return executeInteraction(rule)
    }
    
    func handleInvalidUse(item: Item, target: Entity) -> UsageResult {
        // Check for near-misses
        if isCloseToCorrect(item: item, target: target) {
            return .almostRight(hint: "Try something similar!")
        }
        
        // Check for funny combinations
        if let funnyResponse = getFunnyResponse(item: item, target: target) {
            return .funny(message: funnyResponse)
        }
        
        // Generic failure
        return .invalid(message: "That doesn't work here.")
    }
}
```

### Smart Hints
```swift
class ItemHintSystem {
    func getHint(for puzzle: Puzzle) -> ItemHint {
        let inventory = GameState.current.inventory
        
        // Check if player has required items
        if let missingItem = puzzle.requiredItems.first(where: { !inventory.contains($0) }) {
            return .needItem(missingItem)
        }
        
        // Check if items need combining first
        if let combination = puzzle.requiredCombination {
            if inventory.contains(combination.inputs) && !inventory.contains(combination.output) {
                return .tryCombining(combination.inputs)
            }
        }
        
        // Suggest where to use item
        if let correctItem = puzzle.solution.item {
            return .useItemHere(correctItem, target: puzzle.target)
        }
        
        return .explore  // Generic exploration hint
    }
}
```

## Inventory Management

### Auto-Organization
```swift
class InventoryOrganizer {
    enum SortStrategy {
        case chronological    // Order acquired
        case alphabetical     // By name
        case frequency        // Most used first
        case questRelevance   // Current quest items first
        case type            // Group similar items
    }
    
    func autoOrganize(items: [Item], strategy: SortStrategy) -> [Item] {
        switch strategy {
        case .questRelevance:
            // Prioritize items needed for current puzzles
            let questItems = items.filter { isQuestRelevant($0) }
            let otherItems = items.filter { !isQuestRelevant($0) }
            return questItems + otherItems
            
        case .type:
            // Group by category (tools, food, keys, etc.)
            return items.sorted { $0.category < $1.category }
            
        default:
            return standardSort(items, by: strategy)
        }
    }
}
```

## Consequences

### Positive
- **Discoverable**: Visual feedback guides correct usage
- **Forgiving**: Can't permanently fail or lose items
- **Educational**: Logical combinations teach cause-effect
- **Entertaining**: Funny failures keep mood light
- **Accessible**: Multiple hints prevent stuck states

### Negative
- **Complex implementation**: Many systems to coordinate
- **Art requirements**: Need icons, animations, effects
- **Balancing difficulty**: Hints might make too easy
- **Testing burden**: Many combinations to validate

## Alternatives Considered

1. **Text-Based Combinations**
   - Rejected: Not accessible for pre-readers

2. **Recipe Book System**
   - Rejected: Too much like following instructions

3. **Random Combinations**
   - Rejected: Removes logical thinking aspect

4. **Single-Use Items**
   - Rejected: Too punishing for experimentation

5. **Verb-Based Interface**
   - Rejected: Too complex for age group

## Implementation Priority
1. Basic item usage on world objects
2. Visual feedback for valid/invalid targets
3. Simple two-item combinations
4. Hint system for stuck states
5. Funny failure responses
6. Advanced combination animations
7. Auto-organization features

## Testing Considerations
- Validate all item combinations make logical sense
- Test colorblind accessibility of visual feedback
- Ensure hints don't trivialize puzzles
- Monitor player frustration with failed attempts
- Track which combinations kids try first

## References
- [Designing Reward Systems for Kids](https://www.gamasutra.com/view/feature/131735/designing_rewards_in_games_for_.php)
- [Point-and-Click Design Patterns](https://www.adventuregamestudio.co.uk/wiki/Good_practices_for_adventure_game_design)
- [Inventory Systems in Games](https://www.gamedeveloper.com/design/the-inventory-system-evolution)
- [Educational Game Mechanics](https://www.researchgate.net/publication/262168213_Educational_Game_Design)