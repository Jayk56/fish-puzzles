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
        
        // Check HUD overlays first (for modal dialogs, etc.)
        if let hudManager = hudManager {
            if hudManager.handleTouch(at: location) {
                return  // HUD overlay handled the touch, don't process further
            }
        }
        
        // Check game interactions (including HUD buttons registered as hotspots)
        if let handled = interactionSystem?.handleTouch(at: location), handled {
            return  // Interaction was handled, don't process further
        }
        
        // If nothing handled the touch, subclasses can process it (e.g., move character)
    }
}
