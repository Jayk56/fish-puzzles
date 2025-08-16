//
//  Location2Scene.swift
//  fish-puzzles
//
//  Second location in the game
//

import SpriteKit

class Location2Scene: BaseGameScene {
    override func setupScene() {
        super.setupScene()
        
        // Background
        let background = SKSpriteNode(color: .blue, size: size)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
        
        // Add scene-specific content here
    }
}
