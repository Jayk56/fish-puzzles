//
//  HUDContainer.swift
//  fish-puzzles
//
//  Custom container for HUD elements with proper touch handling
//

import SpriteKit

class HUDContainer: SKNode {
    weak var hudManager: HUDManager?
    
    override init() {
        super.init()
        // Enable touch handling for this container
        isUserInteractionEnabled = true
        name = "HUDContainer"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if any active overlay wants to handle this touch
        if let hudManager = hudManager {
            // Let active overlays handle the touch
            // Modal overlays will block touches from reaching the game
            for overlay in children {
                if let overlayNode = overlay as? BaseOverlay,
                   !overlayNode.isHidden {
                    // Convert to overlay's coordinate space
                    let overlayLocation = convert(location, to: overlayNode)
                    
                    // Check if overlay contains the touch
                    if overlayNode.isModal || overlayNode.containsTouch(at: overlayLocation) {
                        // Let the overlay handle it via its own touchesBegan
                        // Touch will propagate to the overlay automatically
                        // due to isUserInteractionEnabled on overlays
                        return
                    }
                }
            }
        }
        
        // If no overlay handled it, let it pass through to the scene
        // by not calling super (allowing touch to continue to scene)
    }
}