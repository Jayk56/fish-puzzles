# ADR-007: Entity Interaction Zones and Navigation Boundaries

## Status
Accepted

## Context
In a point-and-click adventure game, players need clear visual and interactive feedback about:
- Where characters can move
- Which areas are blocked by scenery
- How to approach interactive objects
- Natural movement paths that respect scene depth

We need a system that prevents the fish character from swimming over/behind furniture while providing intuitive navigation.

## Decision
Implement a zone-based navigation system where entities define:
1. **Navigation Zones**: Designated areas where the fish swims to for interaction
2. **Collision Boundaries**: Blocked areas that prevent movement
3. **Depth Layers**: Z-ordering for proper visual overlap
4. **Approach Points**: Specific positions for interaction animations

## Implementation
```swift
// NavigationZoneComponent.swift
struct NavigationZoneComponent: Component {
    let approachPoint: CGPoint      // Where fish swims to
    let interactionRadius: CGFloat  // How close fish needs to be
    let blockedAreas: [CGRect]      // Areas fish cannot enter
    let depthLayer: Int              // Z-order for rendering
}

// CollisionBoundaryComponent.swift  
struct CollisionBoundaryComponent: Component {
    let boundary: CGPath             // Complex shape support
    let type: BoundaryType           // .solid, .semiSolid, .trigger
    let allowsPathfinding: Bool      // Can path around it
}

// PathfindingSystem.swift
class PathfindingSystem {
    func findPath(from: CGPoint, to: CGPoint, avoiding: [CollisionBoundary]) -> [CGPoint]
    func getNearestAccessiblePoint(target: CGPoint, from: CGPoint) -> CGPoint
}
```

## Entity Configuration Examples

### Treasure Chest
```swift
// Chest blocks area behind it, fish swims to front
entity.add(NavigationZoneComponent(
    approachPoint: CGPoint(x: chest.x, y: chest.y - 50),
    interactionRadius: 40,
    blockedAreas: [CGRect(x: chest.x - 30, y: chest.y, width: 60, height: 40)],
    depthLayer: 2
))
```

### Bookshelf
```swift
// Tall furniture blocks large area, multiple interaction points
entity.add(NavigationZoneComponent(
    approachPoint: CGPoint(x: shelf.x, y: shelf.y - 60),
    interactionRadius: 50,
    blockedAreas: [CGRect(x: shelf.x - 40, y: shelf.y - 20, width: 80, height: 100)],
    depthLayer: 3
))
```

## Consequences

### Positive
- **Natural movement**: Fish navigates realistically around obstacles
- **Clear affordances**: Players understand where they can/cannot go
- **Depth perception**: Proper layering creates believable 2.5D scenes
- **Flexible design**: Designers can create complex interactive spaces
- **Performance**: Zone checks are faster than pixel-perfect collision
- **Debugging**: Visual zone overlay aids level design

### Negative
- **Setup complexity**: Each entity needs zone configuration
- **Pathfinding cost**: A* algorithm has computational overhead
- **Edge cases**: Complex geometries may create navigation bugs
- **Learning curve**: Level designers need to understand zone system

### Risks
- **Player frustration**: Invisible walls if zones aren't intuitive
- **Navigation bugs**: Fish getting stuck in complex geometries

## Alternatives Considered

1. **Pixel-perfect collision**: Check sprite masks for collision
   - Rejected: Too expensive for mobile, hard to debug

2. **Grid-based navigation**: Tile-based movement system
   - Rejected: Too rigid for organic underwater movement

3. **Physics bodies**: SpriteKit physics for collision
   - Rejected: Overkill for point-and-click, unpredictable behavior

4. **Simple rectangles**: Basic AABB collision only
   - Rejected: Not flexible enough for varied entity shapes

## Visual Feedback System
```swift
// Visual indicators for blocked areas (debug mode)
struct ZoneDebugRenderer {
    func showNavigableArea(scene: SKScene)    // Green overlay
    func showBlockedAreas(scene: SKScene)     // Red overlay
    func showApproachPoints(scene: SKScene)   // Blue markers
}
```

## Integration with Level Editor
The level authoring tool will provide:
- Visual zone painting tools
- Automatic zone generation from sprite bounds
- Zone template library for common objects
- Real-time zone preview during editing

## References
- [A* Pathfinding for Beginners](https://www.redblobgames.com/pathfinding/a-star/introduction.html)
- [Navigation Meshes in Games](https://docs.unrealengine.com/en-US/Engine/AI/BehaviorTrees/QuickStart/2/index.html)