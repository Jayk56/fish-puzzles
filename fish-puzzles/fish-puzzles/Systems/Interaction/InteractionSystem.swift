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
    
    init(scene: BaseGameScene) {
        self.scene = scene
    }
    
    func registerHotspot(_ hotspot: Hotspot) {
        hotspots.append(hotspot)
    }
    
    func removeHotspot(id: String) {
        hotspots.removeAll { $0.id == id }
    }
    
    func handleTouch(at point: CGPoint) -> Bool {
        // Check hotspots
        for hotspot in hotspots {
            if hotspot.contains(point) {
                hotspot.action()
                AudioManager.shared.playSFX("tap")
                return true
            }
        }
        
        // Check entities with interaction components
        var handled = false
        scene?.entities.forEach { entity in
            guard let node = entity.node,
                  let _ = entity.get(InteractableComponent.self) else { return }
            
            if node.contains(point) {
                handleEntityInteraction(entity)
                handled = true
            }
        }
        
        return handled
    }
    
    private func handleEntityInteraction(_ entity: Entity) {
        // Handle entity interaction
        if let interactable = entity.get(InteractableComponent.self) {
            interactable.interact()
        }
    }
}
