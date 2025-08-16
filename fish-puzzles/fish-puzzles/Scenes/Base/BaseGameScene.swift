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
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
    }
    
    func setupScene() {
        // Override in subclasses
        interactionSystem = InteractionSystem(scene: self)
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - (lastUpdateTime ?? currentTime)
        lastUpdateTime = currentTime
        
        entities.forEach { $0.update(deltaTime: deltaTime) }
    }
    
    private var lastUpdateTime: TimeInterval?
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        interactionSystem?.handleTouch(at: location)
    }
}
