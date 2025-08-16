# ADR-002: Entity-Component System for Game Objects

## Status
Accepted

## Context
Point-and-click adventures involve many interactive objects with varying behaviors. We need a flexible system to manage game objects that can:
- Share common behaviors (clickable, animated, collectible)
- Be easily extended with new behaviors
- Support runtime composition
- Enable efficient memory usage

## Decision
Implement a lightweight Entity-Component System (ECS) for managing game objects, where:
- **Entities**: Game objects (characters, items, hotspots)
- **Components**: Data containers (position, sprite, interaction data)
- **Systems**: Logic processors (render system, physics system, interaction system)

## Implementation
```swift
// Entity = ID + component collection
class Entity {
    let id: UUID
    private var components: [ObjectIdentifier: Component] = [:]
}

// Components = pure data
struct SpriteComponent: Component {
    var texture: SKTexture
    var size: CGSize
}

struct InteractionComponent: Component {
    var hotspotArea: CGRect
    var onTap: () -> Void
}

// Systems = logic
class RenderSystem {
    func update(entities: [Entity])
}
```

## Consequences

### Positive
- **Flexibility**: Easy to add new behaviors without modifying existing code
- **Reusability**: Components can be mixed and matched
- **Performance**: Cache-friendly data layout, efficient batch processing
- **Testability**: Components and systems can be tested in isolation
- **Debugging**: Clear separation of data and logic
- **Save system**: Components serialize naturally

### Negative
- **Complexity**: More abstraction than simple inheritance
- **Learning curve**: Team needs to understand ECS patterns
- **Boilerplate**: More initial setup code required
- **Debugging overhead**: Indirection can make debugging harder

## Alternatives Considered

1. **Traditional OOP/Inheritance**: Simple class hierarchy
   - Rejected: Leads to deep inheritance trees, inflexible for varied behaviors

2. **Protocol-Oriented**: Swift protocols with extensions
   - Rejected: Can't easily compose behaviors at runtime

3. **Simple struct-based**: Plain data structures
   - Rejected: Lacks flexibility for complex interactions

## References
- [Apple GameplayKit Entity-Component](https://developer.apple.com/documentation/gameplaykit/gkentity)
- [Game Programming Patterns - Component](https://gameprogrammingpatterns.com/component.html)