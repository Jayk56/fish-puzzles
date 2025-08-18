# ADR-013: Visual Feedback and Affordances System

## Status
Proposed

## Context
Young children (ages 4-9) rely heavily on visual cues to understand interactive elements and system state. Unlike adults who can infer functionality from context, children need explicit visual affordances that:

- Clearly indicate what can be interacted with
- Show the current state of interactions
- Provide immediate feedback for all actions
- Guide discovery without overwhelming

Research indicates children in this age range:
- Process visual information faster than text
- Learn through experimentation and feedback
- Need consistent visual language across the game
- Benefit from redundant cues (visual + audio + haptic)

## Decision
Implement a comprehensive visual feedback system that makes all interactions discoverable, provides clear state information, and guides players through consistent visual language.

### Core Principles
1. **Everything interactive glows/moves**: Static objects are non-interactive
2. **Feedback before action**: Show what will happen before it happens
3. **Consistent visual language**: Same effect = same meaning everywhere
4. **Progressive revelation**: Stronger hints over time if stuck
5. **Celebration over punishment**: Positive reinforcement for all attempts

## Visual Affordance System

### Interaction Indicators
```swift
enum InteractionAffordance {
    case none
    case subtle(InteractionType)
    case moderate(InteractionType)
    case strong(InteractionType)
    case urgent(InteractionType)
    
    var visualEffect: VisualEffect {
        switch self {
        case .none:
            return .none
            
        case .subtle(let type):
            return VisualEffect(
                glow: GlowEffect(
                    color: type.color.withAlpha(0.3),
                    radius: 5,
                    pulseRate: 0.5
                ),
                particles: nil,
                animation: .gentleBob(amplitude: 2)
            )
            
        case .moderate(let type):
            return VisualEffect(
                glow: GlowEffect(
                    color: type.color.withAlpha(0.6),
                    radius: 10,
                    pulseRate: 1.0
                ),
                particles: .sparkles(density: .low),
                animation: .breathing(scale: 1.05)
            )
            
        case .strong(let type):
            return VisualEffect(
                glow: GlowEffect(
                    color: type.color,
                    radius: 15,
                    pulseRate: 2.0
                ),
                particles: .sparkles(density: .medium),
                animation: .bounce(height: 5)
            )
            
        case .urgent(let type):
            return VisualEffect(
                glow: GlowEffect(
                    color: type.color,
                    radius: 20,
                    pulseRate: 3.0
                ),
                particles: .sparkles(density: .high),
                animation: .wiggle(intensity: .high),
                arrow: .pointing(animated: true)
            )
        }
    }
}
```

### Hotspot Visualization
```swift
class HotspotVisualizer {
    struct HotspotAppearance {
        let idleState: IdleAnimation
        let hoverState: HoverAnimation
        let activeState: ActiveAnimation
        let cooldownState: CooldownAnimation
    }
    
    enum IdleAnimation {
        case shimmer(interval: TimeInterval)
        case outline(color: UIColor, width: CGFloat)
        case particles(type: ParticleType, rate: Float)
        case glow(color: UIColor, intensity: Float)
    }
    
    enum HoverAnimation {
        case expand(scale: CGFloat)
        case brighten(factor: Float)
        case ripple(color: UIColor)
        case highlight(borderWidth: CGFloat)
    }
    
    func updateHotspotVisuals(
        hotspot: Hotspot,
        playerDistance: CGFloat,
        timeStuck: TimeInterval?
    ) {
        // Progressive hint system
        if let stuckTime = timeStuck {
            switch stuckTime {
            case 0..<10:
                hotspot.setAffordance(.subtle)
            case 10..<20:
                hotspot.setAffordance(.moderate)
            case 20..<30:
                hotspot.setAffordance(.strong)
            default:
                hotspot.setAffordance(.urgent)
            }
        } else {
            // Distance-based highlighting
            switch playerDistance {
            case 0..<100:
                hotspot.setAffordance(.moderate)
            case 100..<200:
                hotspot.setAffordance(.subtle)
            default:
                hotspot.setAffordance(.none)
            }
        }
    }
}
```

## State Feedback

### Character Movement Feedback
```swift
class MovementFeedback {
    func showPathPreview(from: CGPoint, to: CGPoint) {
        // Dotted line path
        // Footstep markers
        // Destination ripple
    }
    
    func showMoving(progress: Float) {
        // Dust particles at feet
        // Motion blur on character
        // Speed lines when running
    }
    
    func showArrival() {
        // Settling animation
        // Dust cloud dissipate
        // Character idle transition
    }
    
    func showBlocked(reason: BlockedReason) {
        switch reason {
        case .obstacle:
            // Bump animation
            // Collision particles
            // "Oof" expression
            
        case .tooFar:
            // Head shake
            // Question mark bubble
            // Point at obstacle
            
        case .locked:
            // Try door handle animation
            // Lock icon appear
            // Frustrated expression
        }
    }
}
```

### Item Interaction Feedback
```swift
class ItemFeedback {
    struct ItemSelectionVisual {
        let float: FloatingAnimation
        let glow: GlowEffect
        let cursor: CursorAttachment
        let trail: ParticleTrail?
    }
    
    func showItemPickup(item: Item, from: CGPoint) {
        // Item scales up
        // Spirals to inventory
        // Sparkle trail
        // Slot highlight on arrival
        // Success sound
    }
    
    func showItemUse(item: Item, on target: Entity, success: Bool) {
        if success {
            // Item flies to target
            // Merge animation
            // Success particles
            // Target transforms
        } else {
            // Item bounces off
            // Red flash on target
            // Shake animation
            // Return to inventory
        }
    }
    
    func showItemCombination(item1: Item, item2: Item) -> SKAction {
        return SKAction.sequence([
            // Items move together
            SKAction.group([
                item1.moveTo(center),
                item2.moveTo(center)
            ]),
            // Spinning merge
            SKAction.customAction(duration: 0.5) { node, time in
                node.zRotation = time * .pi * 4
                node.setScale(1.0 - time * 0.5)
            },
            // Flash and transform
            SKAction.flashWhite(),
            // New item appears
            SKAction.spawn(newItem)
        ])
    }
}
```

## Progressive Hint System

### Hint Escalation
```swift
class ProgressiveHintSystem {
    enum HintLevel: Int {
        case none = 0
        case environmental = 1    // Subtle world hints
        case interface = 2        // UI element highlights
        case directional = 3      // Arrows/paths
        case explicit = 4         // Direct instructions
        
        var timing: TimeInterval {
            switch self {
            case .none: return 0
            case .environmental: return 15
            case .interface: return 30
            case .directional: return 45
            case .explicit: return 60
            }
        }
    }
    
    func getHintVisual(
        for puzzle: Puzzle,
        stuckTime: TimeInterval
    ) -> HintVisual? {
        let level = HintLevel.allCases.first { 
            stuckTime >= $0.timing 
        } ?? .none
        
        switch level {
        case .none:
            return nil
            
        case .environmental:
            // Make solution object shimmer
            return HintVisual(
                target: puzzle.solutionObject,
                effect: .shimmer(color: .white, intensity: 0.3)
            )
            
        case .interface:
            // Highlight relevant inventory item
            return HintVisual(
                target: puzzle.requiredItem,
                effect: .glow(color: .yellow, radius: 10)
            )
            
        case .directional:
            // Show path to solution
            return HintVisual(
                path: puzzle.solutionPath,
                effect: .breadcrumbs(style: .arrows)
            )
            
        case .explicit:
            // Show ghost performing action
            return HintVisual(
                animation: puzzle.solutionAnimation,
                effect: .ghostPlayer(opacity: 0.5)
            )
        }
    }
}
```

## Particle Effects System

### Contextual Particles
```swift
class ParticleEffectSystem {
    enum ParticleContext {
        case success
        case failure  
        case discovery
        case interaction
        case idle
        case celebration
        
        var emitterConfig: ParticleEmitterConfig {
            switch self {
            case .success:
                return ParticleEmitterConfig(
                    texture: "star",
                    birthRate: 50,
                    lifetime: 1.0,
                    color: .yellow,
                    scale: 0.2...0.5,
                    speed: 100...200,
                    emissionAngle: 0...360
                )
                
            case .discovery:
                return ParticleEmitterConfig(
                    texture: "sparkle",
                    birthRate: 20,
                    lifetime: 2.0,
                    color: .cyan,
                    scale: 0.1...0.3,
                    speed: 50...100,
                    emissionAngle: -45...45
                )
                
            // ... other contexts
            }
        }
    }
    
    func triggerEffect(
        context: ParticleContext,
        at position: CGPoint,
        duration: TimeInterval = 1.0
    ) {
        let emitter = SKEmitterNode()
        emitter.configure(with: context.emitterConfig)
        emitter.position = position
        
        scene.addChild(emitter)
        
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
}
```

## Color Language

### Semantic Colors
```swift
struct GameColorLanguage {
    // Interaction states
    static let interactable = UIColor.systemBlue
    static let selected = UIColor.systemYellow  
    static let valid = UIColor.systemGreen
    static let invalid = UIColor.systemRed
    static let locked = UIColor.systemGray
    static let hint = UIColor.systemPurple
    
    // Item categories
    static let keyItems = UIColor.systemOrange
    static let consumables = UIColor.systemTeal
    static let tools = UIColor.systemBrown
    static let quest = UIColor.systemIndigo
    
    // Feedback
    static let success = UIColor.systemGreen
    static let warning = UIColor.systemYellow
    static let error = UIColor.systemRed
    static let info = UIColor.systemBlue
    
    // Accessibility overrides
    static func colorForColorblindMode(
        _ mode: ColorblindMode,
        semantic: SemanticColor
    ) -> UIColor {
        // Return adjusted colors for different colorblind modes
        switch mode {
        case .protanopia:
            return protanopiaAdjusted[semantic] ?? semantic.defaultColor
        case .deuteranopia:
            return deuteranopiaAdjusted[semantic] ?? semantic.defaultColor
        case .tritanopia:
            return tritanopiaAdjusted[semantic] ?? semantic.defaultColor
        case .none:
            return semantic.defaultColor
        }
    }
}
```

## Animation Timing

### Kid-Friendly Timing
```swift
struct AnimationTiming {
    // Slower than typical for better visibility
    static let instant: TimeInterval = 0.1
    static let fast: TimeInterval = 0.3
    static let normal: TimeInterval = 0.5
    static let slow: TimeInterval = 0.8
    static let verySlow: TimeInterval = 1.2
    
    // Easing curves optimized for children
    enum KidEasing {
        case bouncy      // Fun, energetic
        case smooth      // Calm, predictable  
        case snappy      // Quick but visible
        case gentle      // Slow, non-jarring
        
        var timingFunction: SKActionTimingMode {
            switch self {
            case .bouncy: return .easeInEaseOut
            case .smooth: return .easeOut
            case .snappy: return .easeIn
            case .gentle: return .linear
            }
        }
    }
}
```

## Consequences

### Positive
- **Discoverable**: Players can find interactions without instruction
- **Inclusive**: Works for various cognitive abilities
- **Engaging**: Animations and particles maintain interest
- **Clear**: Unambiguous state communication
- **Supportive**: Progressive hints prevent frustration

### Negative
- **Performance cost**: Many simultaneous effects
- **Visual noise**: Risk of overwhelming sensitive children
- **Art burden**: Many assets needed for effects
- **Complexity**: Coordinating multiple feedback systems

## Alternatives Considered

1. **Minimal feedback**
   - Rejected: Children need explicit guidance

2. **Text-based hints**
   - Rejected: Not accessible for pre-readers

3. **Audio-only feedback**
   - Rejected: Not inclusive for hearing impaired

4. **Realistic graphics**
   - Rejected: Stylized visuals more clearly convey state

5. **Adult-oriented timing**
   - Rejected: Too fast for developing motor skills

## Implementation Priority
1. Basic hotspot glow system
2. Touch feedback animations
3. Item selection visuals
4. Success/failure particles
5. Progressive hint system
6. Advanced particle effects
7. Colorblind modes

## Testing Requirements
- Validate with colorblind users
- Test with children prone to sensory overload
- Measure discoverability of interactions
- Monitor performance with all effects active
- Verify animations are smooth at 60 FPS

## References
- [Visual Design for Children](https://www.nngroup.com/articles/visual-design-children/)
- [Animation in Children's Apps](https://www.smashingmagazine.com/2015/06/design-principles-for-kids-apps/)
- [Feedback Systems in Games](https://www.gamasutra.com/view/feature/132611/the_art_of_feedback.php)
- [Affordances in Game Design](https://www.gdcvault.com/play/1015290/Affordances-in-Game-Design)