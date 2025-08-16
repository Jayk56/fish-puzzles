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
}
