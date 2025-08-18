//
//  InteractableComponent.swift
//  fish-puzzles
//
//  Component for interactive entities
//

import Foundation

class InteractableComponent: Component {
    var interactionRadius: CGFloat = 50
    var requiredItem: String?
    var onInteract: (() -> Void)?
    
    // Interaction types
    var canPickUp: Bool = false
    var canTalkTo: Bool = false
    var canExamine: Bool = true
    var requiresTool: Bool = false
    var entityType: EntityType = .object
    
    func interact() {
        // Check if we have required item
        if let requiredItem = requiredItem {
            guard GameEngine.shared.gameState.inventory.contains(requiredItem) else {
                print("Need item: \(requiredItem)")
                return
            }
        }
        
        onInteract?()
    }
    
    func canInteractWith(item: Item?) -> Bool {
        if let requiredItemId = requiredItem {
            return item?.id == requiredItemId
        }
        return item == nil // Can interact without item
    }
}
