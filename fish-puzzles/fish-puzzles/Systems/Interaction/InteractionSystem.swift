//
//  InteractionSystem.swift
//  fish-puzzles
//
//  Handles touch interactions and hotspots
//

import SpriteKit

struct Hotspot {
    let id: String
    let frame: CGRect
    let action: () -> Void
    
    func contains(_ point: CGPoint) -> Bool {
        frame.contains(point)
    }
}

final class InteractionSystem {
    weak var scene: BaseGameScene?
    private var hotspots: [Hotspot] = []
    private var itemCursor: ItemCursor?
    private var highlightedHotspots: Set<String> = []
    
    init(scene: BaseGameScene) {
        self.scene = scene
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
    }
    
    func removeHotspot(id: String) {
        hotspots.removeAll { $0.id == id }
        highlightedHotspots.remove(id)
    }
    
    func handleTouch(at point: CGPoint) -> Bool {
        // Reset hint system on interaction
        ProgressiveHintSystem.shared.playerInteracted()
        
        // Check if we have a selected item
        if let selectedItem = InventoryManager.shared.selectedItem {
            return handleItemUse(item: selectedItem, at: point)
        }
        
        // Check hotspots
        for hotspot in hotspots {
            if hotspot.contains(point) {
                hotspot.action()
                AudioManager.shared.playSFX("tap")
                VisualFeedbackSystem.shared.showInteractionFeedback(
                    at: point,
                    type: .use
                )
                return true
            }
        }
        
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
        
        // If nothing was interacted with, move character
        if !handled {
            moveCharacter(to: point)
        }
        
        return handled
    }
    
    private func handleItemUse(item: Item, at point: CGPoint) -> Bool {
        // Find target entity at point
        if let targetEntity = findEntity(at: point) {
            let result = InventoryManager.shared.useItem(item, on: targetEntity)
            
            switch result {
            case .success(let effects):
                executeEffects(effects)
                VisualFeedbackSystem.shared.showSuccess(at: point)
                itemCursor?.animateUse(success: true) {
                    InventoryManager.shared.selectItem(nil)
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
        InventoryManager.shared.selectItem(nil)
        return false
    }
    
    private func handleEntityInteraction(_ entity: Entity, at point: CGPoint) {
        if let interactable = entity.get(InteractableComponent.self) {
            let interactionType = determineInteractionType(for: entity)
            VisualFeedbackSystem.shared.showInteractionFeedback(
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
        VisualFeedbackSystem.shared.showInteractionFeedback(
            at: point,
            type: .move
        )
        
        // TODO: Implement actual character movement
        scene?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.run {
                AudioManager.shared.playSFX("footstep")
            }
        ]))
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
                    VisualFeedbackSystem.shared.showValidTarget(node: node)
                }
            }
        }
    }
    
    private func clearHighlights() {
        VisualFeedbackSystem.shared.clearAllEffects()
        highlightedHotspots.removeAll()
    }
    
    private func executeEffects(_ effects: [Effect]) {
        for effect in effects {
            DispatchQueue.main.asyncAfter(deadline: .now() + effect.delay) {
                self.executeEffect(effect)
            }
        }
    }
    
    private func executeEffect(_ effect: Effect) {
        switch effect.type {
        case .playSound(let sound):
            AudioManager.shared.playSFX(sound)
            
        case .playAnimation(let animation):
            if effect.target?.node != nil {
                // TODO: Play animation on target
                print("Playing animation: \(animation)")
            }
            
        case .showParticles(let particles):
            if effect.target?.node != nil {
                // TODO: Show particles
                print("Showing particles: \(particles)")
            }
            
        case .changeSprite(let sprite):
            if let target = effect.target?.node as? SKSpriteNode {
                target.texture = SKTexture(imageNamed: sprite)
            }
            
        case .unlock(let id):
            // TODO: Unlock entity with id
            print("Unlocking: \(id)")
            
        case .triggerDialogue(let dialogue):
            // TODO: Trigger dialogue
            print("Triggering dialogue: \(dialogue)")
        }
    }
    
    private func showHintMessage(_ message: String) {
        // TODO: Show hint message in HUD
        print("Hint: \(message)")
    }
    
    func updateHotspotHighlights(playerPosition: CGPoint) {
        for hotspot in hotspots {
            let distance = hypot(
                hotspot.frame.midX - playerPosition.x,
                hotspot.frame.midY - playerPosition.y
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
        guard let node = scene?.childNode(withName: hotspot.id) else { return }
        
        let glowLevel: GlowLevel = distance < 50 ? .strong :
                                   distance < 100 ? .moderate : .subtle
        
        VisualFeedbackSystem.shared.showHotspotGlow(on: node, level: glowLevel)
    }
    
    private func unhighlightHotspot(_ hotspot: Hotspot) {
        guard scene?.childNode(withName: hotspot.id) != nil else { return }
        VisualFeedbackSystem.shared.clearAllEffects()
    }
    
    func handleTouchMoved(_ touch: UITouch) {
        guard let scene = scene else { return }
        let location = touch.location(in: scene)
        
        // Update item cursor position if item is selected
        if InventoryManager.shared.selectedItem != nil {
            itemCursor?.updatePosition(location)
            
            // Check if over valid target
            if let targetEntity = findEntity(at: location) {
                if let item = InventoryManager.shared.selectedItem,
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
