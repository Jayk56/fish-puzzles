//
//  InteractionSystem.swift
//  fish-puzzles
//
//  Handles touch interactions and hotspots
//

import SpriteKit

final class InteractionSystem {
    weak var scene: BaseGameScene?
    private var hotspots: [Hotspot] = []
    private var itemCursor: ItemCursor?
    private var highlightedHotspots: Set<String> = []

    // Injected dependencies (scene-scoped by default)
    private let hotspotManager: HotspotManaging
    private let visualFeedback: VisualFeedbackProviding
    private let audio: AudioPlaying
    private let hintSystem: HintProviding
    private let inventory: InventoryManaging

    init(
        scene: BaseGameScene,
        hotspotManager: HotspotManaging = HotspotManager.shared,
        visualFeedback: VisualFeedbackProviding = VisualFeedbackSystem.shared,
        audio: AudioPlaying = AudioManager.shared,
        hintSystem: HintProviding = ProgressiveHintSystem.shared,
        inventory: InventoryManaging = InventoryManager.shared
    ) {
        self.scene = scene
        self.hotspotManager = hotspotManager
        self.visualFeedback = visualFeedback
        self.audio = audio
        self.hintSystem = hintSystem
        self.inventory = inventory
        setupItemCursor()
        setupInventoryCallbacks()
    }
    
    private func setupItemCursor() {
        itemCursor = ItemCursor()
        if let cursor = itemCursor {
            scene?.addChild(cursor)
        }
    }
    
    private func setupInventoryCallbacks() {
        InventoryManager.shared.onItemSelected = { [weak self] item in
            self?.handleItemSelection(item)
        }
    }
    
    func registerHotspot(_ hotspot: Hotspot) {
        hotspots.append(hotspot)
        hotspotManager.register(hotspot)
    }
    
    func removeHotspot(id: String) {
        hotspots.removeAll { $0.id == id }
        highlightedHotspots.remove(id)
        hotspotManager.unregister(id)
    }
    
    func handleTouch(at point: CGPoint) -> Bool {
        print("🔍 InteractionSystem: Handling touch at \(point)")
        // Reset hint system on interaction
        hintSystem.playerInteracted()
        
        // Check if we have a selected item
        if let selectedItem = inventory.selectedItem {
            return handleItemUse(item: selectedItem, at: point)
        }
        
        // Use HotspotManager to detect hotspots, then move to approach point and trigger
        let currentItem = inventory.selectedItem?.id
        print("🔍 InteractionSystem: Checking hotspots with HotspotManager...")
        if let hotspot = hotspotManager.getHotspot(at: point) {
            print("✅ InteractionSystem: Hotspot tapped: \(hotspot.id)")
            audio.playSFX("tap")
            visualFeedback.showInteractionFeedback(at: point, type: .use)
            moveToHotspotAndTrigger(hotspot, with: currentItem)
            return true
        }
        print("❌ InteractionSystem: No hotspot at this point")
        
        // Check entities with interaction components
        var handled = false
        scene?.entities.forEach { entity in
            guard let node = entity.node,
                  let _ = entity.get(InteractableComponent.self) else { return }
            if node.contains(point) {
                handleEntityInteraction(entity, at: point)
                handled = true
            }
        }
        
        // Do not move here; movement is handled by scenes or a dedicated MovementSystem
        return handled
    }
    
    private func handleItemUse(item: Item, at point: CGPoint) -> Bool {
        // Find target entity at point
        if let targetEntity = findEntity(at: point) {
            let result = inventory.useItem(item, on: targetEntity)
            
            switch result {
            case .success(let effects):
                executeEffects(effects)
                visualFeedback.showSuccess(at: point)
                itemCursor?.animateUse(success: true) {
                    self.inventory.selectItem(nil)
                }
                return true
                
            case .partial(let hint, let effects):
                executeEffects(effects)
                showHintMessage(hint)
                itemCursor?.animateUse(success: false) {}
                return true
                
            case .invalid(let reason):
                VisualFeedbackSystem.shared.showInvalidTarget(node: targetEntity.node!)
                showHintMessage(reason)
                itemCursor?.animateUse(success: false) {}
                return false
                
            case .funny(let message):
                showHintMessage(message)
                itemCursor?.animateUse(success: false) {}
                return true
            }
        }
        
        // Deselect item if tapped on empty space
        inventory.selectItem(nil)
        return false
    }
    
    private func handleEntityInteraction(_ entity: Entity, at point: CGPoint) {
        if let interactable = entity.get(InteractableComponent.self) {
            let interactionType = determineInteractionType(for: entity)
            visualFeedback.showInteractionFeedback(
                at: point,
                type: interactionType
            )
            interactable.interact()
        }
    }
    
    private func handleItemSelection(_ item: Item?) {
        if let item = item {
            itemCursor?.attachItem(item)
            highlightValidTargets(for: item)
        } else {
            itemCursor?.detachItem()
            clearHighlights()
        }
    }
    
    private func moveCharacter(to point: CGPoint) {
        // Implement character movement
        visualFeedback.showInteractionFeedback(
            at: point,
            type: .move
        )
        
        // Find the main character entity (usually the first one with a sprite node)
        var characterEntity: Entity?
        scene?.entities.forEach { entity in
            // Look for an entity that might be the player character
            // Check if it has a sprite node and is not an inventory item
            if entity.node is SKSpriteNode,
               entity.get(InteractableComponent.self)?.canPickUp != true {
                characterEntity = entity
                return  // Stop at first suitable entity
            }
        }
        
        // Move the character to the target point
        if let character = characterEntity, let node = character.node {
            let distance = hypot(point.x - node.position.x, point.y - node.position.y)
            let duration = TimeInterval(distance / 200.0) // 200 points per second
            
            let moveAction = SKAction.move(to: point, duration: duration)
            moveAction.timingMode = .easeInEaseOut
            
            // Play footstep sounds during movement
            let footstepAction = SKAction.repeat(
                SKAction.sequence([
                    SKAction.run { self.audio.playSFX("footstep") },
                    SKAction.wait(forDuration: 0.3)
                ]), 
                count: Int(duration / 0.3)
            )
            
            node.run(SKAction.group([moveAction, footstepAction]))
        } else {
            // Fallback: just play sound if no character found
            audio.playSFX("footstep")
        }
    }
    
    private func findEntity(at point: CGPoint) -> Entity? {
        var foundEntity: Entity?
        
        scene?.entities.forEach { entity in
            guard let node = entity.node else { return }
            
            if node.contains(point) {
                foundEntity = entity
            }
        }
        
        return foundEntity
    }
    
    private func determineInteractionType(for entity: Entity) -> InteractionType {
        if entity.get(InteractableComponent.self)?.canPickUp == true {
            return .take
        } else if entity.get(InteractableComponent.self)?.canTalkTo == true {
            return .talk
        } else if entity.get(InteractableComponent.self)?.canExamine == true {
            return .look
        } else {
            return .use
        }
    }
    
    private func highlightValidTargets(for item: Item) {
        scene?.entities.forEach { entity in
            if ItemInteractionEngine.shared.canUseItem(item, on: entity) {
                if let node = entity.node {
                    visualFeedback.showValidTarget(node: node)
                }
            }
        }
    }
    
    private func clearHighlights() {
        visualFeedback.clearAllEffects()
        highlightedHotspots.removeAll()
    }
    
    func executeEffects(_ effects: [Effect]) {
        for effect in effects {
            DispatchQueue.main.asyncAfter(deadline: .now() + effect.delay) {
                self.executeEffect(effect)
            }
        }
    }
    
    private func executeEffect(_ effect: Effect) {
        switch effect.type {
        case .playSound(let sound):
            audio.playSFX(sound)
            
        case .playAnimation(let animation):
            // First check if the target has a CharacterAnimationComponent
            if let animationComponent = effect.target?.get(CharacterAnimationComponent.self) {
                // Use the component's animation system
                switch animation.lowercased() {
                case "idle":
                    animationComponent.playAnimation(.idle)
                case "swimming", "swim":
                    animationComponent.playAnimation(.swimming)
                case "success", "happy", "excited":
                    animationComponent.playAnimation(.success)
                case "confused", "puzzled":
                    animationComponent.playAnimation(.confused)
                default:
                    // Try to play as swimming with repeat count
                    if let count = Int(animation) {
                        animationComponent.playAnimation(.swimming, repeatCount: count)
                    } else {
                        animationComponent.playAnimation(.success)
                    }
                }
            } else if let targetNode = effect.target?.node {
                // No animation component, handle special animations directly
                switch animation.lowercased() {
                case "chest_open", "pearl_rise":
                    // Create pearl animation for treasure chest
                    // Check if this is the chest entity (has a brown sprite node)
                    if let sprite = targetNode as? SKSpriteNode {
                        let pearl = SKShapeNode(circleOfRadius: 15)
                        pearl.fillColor = .white
                        pearl.strokeColor = .systemPink
                        pearl.lineWidth = 2
                        pearl.glowWidth = 5
                        pearl.position = CGPoint(x: 0, y: 20)
                        pearl.alpha = 0
                        targetNode.addChild(pearl)
                        
                        let appear = SKAction.fadeIn(withDuration: 0.3)
                        let rise = SKAction.moveBy(x: 0, y: 80, duration: 1.2)
                        let grow = SKAction.scale(to: 1.8, duration: 1.2)
                        let sparkle = SKAction.rotate(byAngle: .pi * 4, duration: 1.2)
                        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                        
                        let riseGroup = SKAction.group([rise, grow, sparkle])
                        let sequence = SKAction.sequence([appear, riseGroup, fadeOut, SKAction.removeFromParent()])
                        
                        pearl.run(sequence)
                        
                        // Also animate the chest itself
                        let chestScale = SKAction.sequence([
                            SKAction.scale(to: 1.1, duration: 0.2),
                            SKAction.scale(to: 1.0, duration: 0.2)
                        ])
                        sprite.run(chestScale)
                        
                        self.audio.playSFX("magic_sparkle")
                    }
                    
                default:
                    // Try to run as a generic sprite animation
                    if let sprite = targetNode as? SKSpriteNode {
                        if animation.contains("_") {
                            // Frame-based animation
                            let parts = animation.split(separator: "_")
                            let baseName = String(parts[0])
                            let frameCount = Int(parts.count > 1 ? String(parts[1]) : "1") ?? 1
                            let duration = Double(parts.count > 2 ? String(parts[2]) : "1.0") ?? 1.0
                            
                            var textures: [SKTexture] = []
                            for i in 1...frameCount {
                                textures.append(SKTexture(imageNamed: "\(baseName)\(i)"))
                            }
                            
                            let animateAction = SKAction.animate(with: textures, 
                                                                timePerFrame: duration / Double(frameCount))
                            sprite.run(animateAction)
                        } else {
                            // Single texture change
                            sprite.texture = SKTexture(imageNamed: animation)
                        }
                    }
                }
            }
            
        case .showParticles(let particles):
            if let targetNode = effect.target?.node {
                // Try to load particle file first
                if let particleFile = Bundle.main.path(forResource: particles, ofType: "sks"),
                   let emitterData = try? Data(contentsOf: URL(fileURLWithPath: particleFile)),
                   let emitter = try? NSKeyedUnarchiver.unarchivedObject(ofClass: SKEmitterNode.self, from: emitterData) {
                    emitter.position = .zero
                    emitter.targetNode = targetNode.parent
                    targetNode.addChild(emitter)
                    
                    // Auto-remove after particle lifetime
                    let duration = emitter.particleLifetime + emitter.particleLifetimeRange
                    emitter.run(SKAction.sequence([
                        SKAction.wait(forDuration: TimeInterval(duration)),
                        SKAction.removeFromParent()
                    ]))
                } else {
                    // Create a simple particle effect programmatically
                    let emitter = SKEmitterNode()
                    emitter.position = .zero
                    
                    // Configure based on particle name
                    switch particles.lowercased() {
                    case "sparkle", "star":
                        emitter.particleTexture = SKTexture(imageNamed: "spark")
                        emitter.particleBirthRate = 30
                        emitter.particleLifetime = 1.0
                        emitter.particleScale = 0.2
                        emitter.particleScaleRange = 0.1
                        emitter.particleAlpha = 0.8
                        emitter.particleAlphaRange = 0.2
                        emitter.particleSpeed = 50
                        emitter.emissionAngleRange = .pi * 2
                        
                    case "smoke":
                        emitter.particleTexture = SKTexture(imageNamed: "smoke")
                        emitter.particleBirthRate = 10
                        emitter.particleLifetime = 2.0
                        emitter.particleScale = 0.5
                        emitter.particleAlpha = 0.5
                        emitter.particleSpeed = 30
                        emitter.emissionAngle = .pi / 2
                        emitter.yAcceleration = 20
                        
                    case "dust":
                        emitter.particleTexture = SKTexture(imageNamed: "dust")
                        emitter.particleBirthRate = 20
                        emitter.particleLifetime = 1.5
                        emitter.particleScale = 0.1
                        emitter.particleSpeed = 20
                        emitter.emissionAngleRange = .pi * 2
                        
                    default:
                        // Generic particle effect
                        emitter.particleTexture = SKTexture(imageNamed: "particle")
                        emitter.particleBirthRate = 15
                        emitter.particleLifetime = 1.0
                        emitter.particleScale = 0.3
                        emitter.particleSpeed = 40
                    }
                    
                    emitter.numParticlesToEmit = Int(emitter.particleBirthRate * emitter.particleLifetime)
                    targetNode.addChild(emitter)
                    
                    // Auto-remove after completion
                    emitter.run(SKAction.sequence([
                        SKAction.wait(forDuration: TimeInterval(emitter.particleLifetime + 0.5)),
                        SKAction.removeFromParent()
                    ]))
                }
            }
            
        case .changeSprite(let sprite):
            if let target = effect.target?.node as? SKSpriteNode {
                target.texture = SKTexture(imageNamed: sprite)
            }
            
        case .unlock(let id):
            scene?.entities.forEach { entity in
                if entity.id.uuidString == id {
                    // Mark entity as unlocked by enabling interaction
                    if let interactable = entity.get(InteractableComponent.self) {
                        // Remove any required item to make it freely interactable
                        interactable.requiredItem = nil
                        
                        // Visual feedback for unlock
                        if let node = entity.node {
                            self.visualFeedback.showInteractionFeedback(
                                at: node.position,
                                type: .use
                            )
                            self.audio.playSFX("unlock")
                        }
                    }
                }
            }
            
        case .triggerDialogue(let dialogue):
            if let dialogueOverlay = scene?.hudManager?.overlays[.dialogue] as? DialogueOverlay {
                // Parse dialogue string - format expected: "CharacterName:DialogueText"
                let parts = dialogue.split(separator: ":", maxSplits: 1)
                let characterName = parts.count > 0 ? String(parts[0]) : "Unknown"
                let text = parts.count > 1 ? String(parts[1]) : dialogue
                
                dialogueOverlay.showDialogue(character: characterName, text: text)
                scene?.hudManager?.show(.dialogue)
            }
        }
    }
    
    private func showHintMessage(_ message: String) {
        if let hintOverlay = scene?.hudManager?.overlays[.hint] as? HintOverlay {
            hintOverlay.showHint(message, level: .subtle)
            scene?.hudManager?.show(.hint)
        }
    }
    
    func updateHotspotHighlights(playerPosition: CGPoint) {
        for hotspot in hotspots {
            let distance = hypot(
                hotspot.area.midX - playerPosition.x,
                hotspot.area.midY - playerPosition.y
            )
            
            if distance < 150 && !highlightedHotspots.contains(hotspot.id) {
                highlightHotspot(hotspot, distance: distance)
                highlightedHotspots.insert(hotspot.id)
            } else if distance >= 150 && highlightedHotspots.contains(hotspot.id) {
                unhighlightHotspot(hotspot)
                highlightedHotspots.remove(hotspot.id)
            }
        }
    }
    
    private func highlightHotspot(_ hotspot: Hotspot, distance: CGFloat) {
        guard let node = hotspot.node ?? scene?.childNode(withName: hotspot.id) else { return }
        let glowLevel: GlowLevel = distance < 50 ? .strong : distance < 100 ? .moderate : .subtle
        visualFeedback.showHotspotGlow(on: node, level: glowLevel)
    }
    
    private func unhighlightHotspot(_ hotspot: Hotspot) {
        guard let node = hotspot.node ?? scene?.childNode(withName: hotspot.id) else { return }
        visualFeedback.clearEffects(on: node)
    }
    
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene = scene else { return }
        let location = touch.location(in: scene)
        
        // Update item cursor position if item is selected
        if inventory.selectedItem != nil {
            itemCursor?.updatePosition(location)
            
            // Check if over valid target
            if let targetEntity = findEntity(at: location) {
                if let item = inventory.selectedItem,
                   ItemInteractionEngine.shared.canUseItem(item, on: targetEntity) {
                    itemCursor?.showValidTarget()
                } else {
                    itemCursor?.showInvalidTarget()
                }
            } else {
                itemCursor?.showNeutral()
            }
        }
    }
}

// MARK: - Hotspot Movement Coordination
extension InteractionSystem {
    private func moveToHotspotAndTrigger(_ hotspot: Hotspot, with item: String?) {
        guard let scene = scene else { return }
        let approach = approachPoint(for: hotspot)
        scene.movementSystem?.movePlayer(to: approach) { [weak hotspot] in
            hotspot?.trigger(with: item)
        }
    }
    
    private func approachPoint(for hotspot: Hotspot) -> CGPoint {
        // Prefer an explicit navigation zone if the hotspot's node belongs to an entity
        if let node = hotspot.node, let entity = resolveEntity(from: node) {
            if let zone = entity.get(NavigationZoneComponent.self) {
                return zone.approachPoint
            }
        }
        // Fallback just below the hotspot area
        return CGPoint(x: hotspot.area.midX, y: hotspot.area.minY - 40)
    }
    
    private func resolveEntity(from node: SKNode) -> Entity? {
        var current: SKNode? = node
        while let n = current {
            if let entity = scene?.entities.first(where: { $0.node === n }) {
                return entity
            }
            current = n.parent
        }
        return nil
    }
}
