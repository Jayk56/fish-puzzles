//
//  BaseGameScene.swift
//  fish-puzzles
//
//  Base class for all game scenes
//

import SpriteKit

class BaseGameScene: SKScene {
    var entities: [Entity] = []
    var interactionSystem: InteractionSystem!
    var hudManager: HUDManager?
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
    }
    
    func setupScene() {
        // Override in subclasses
        interactionSystem = InteractionSystem(scene: self)
        
        // Initialize HUD for game scenes (not for menu)
        if !(self is MainMenuScene) {
            hudManager = HUDManager(scene: self)
            setupHUD()
        }
    }
    
    func setupHUD() {
        // Override in subclasses to configure HUD
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - (lastUpdateTime ?? currentTime)
        lastUpdateTime = currentTime
        
        entities.forEach { $0.update(deltaTime: deltaTime) }
        hudManager?.update(deltaTime: deltaTime)
    }
    
    private var lastUpdateTime: TimeInterval?
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // With proper isUserInteractionEnabled, touches will be handled by:
        // 1. HUD buttons (highest z-position, isUserInteractionEnabled = true)
        // 2. HUD overlays (in HUDContainer, isUserInteractionEnabled = true)
        // 3. Game hotspots (treasure chest, doors, etc.)
        // 4. Scene itself (for movement)
        
        // Only check game interactions (non-HUD hotspots)
        if let handled = interactionSystem?.handleTouch(at: location), handled {
            return  // A game hotspot was touched
        }
        
        // If nothing handled it, subclasses can process (e.g., move character)
    }
}
