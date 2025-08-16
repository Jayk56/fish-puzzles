//
//  Location1Scene.swift
//  fish-puzzles
//
//  First location in the game
//

import SpriteKit

class Location1Scene: BaseGameScene {
    private var fishCharacter: SKSpriteNode!
    
    override func setupScene() {
        super.setupScene()
        
        // Background - will be replaced with actual art
        let background = SKSpriteNode(color: .cyan, size: size)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
        
        // Add fish character
        setupCharacter()
        
        // Setup hotspots
        setupHotspots()
        
        // Play underwater ambience
        AudioManager.shared.playMusic("underwater_ambience")
    }
    
    private func setupCharacter() {
        fishCharacter = SKSpriteNode(color: .orange, size: CGSize(width: 60, height: 40))
        fishCharacter.position = CGPoint(x: size.width * 0.2, y: size.height * 0.5)
        fishCharacter.name = "player"
        addChild(fishCharacter)
        
        // Add slight floating animation
        let floatUp = SKAction.moveBy(x: 0, y: 10, duration: 2)
        let floatDown = SKAction.moveBy(x: 0, y: -10, duration: 2)
        let sequence = SKAction.sequence([floatUp, floatDown])
        fishCharacter.run(SKAction.repeatForever(sequence))
    }
    
    private func setupHotspots() {
        // Example: Treasure chest hotspot
        let chestHotspot = Hotspot(
            id: "treasure_chest",
            frame: CGRect(x: size.width * 0.7, y: size.height * 0.3, width: 100, height: 100),
            action: { [weak self] in
                self?.openTreasureChest()
            }
        )
        interactionSystem.registerHotspot(chestHotspot)
    }
    
    private func openTreasureChest() {
        print("Opening treasure chest!")
        AudioManager.shared.playSFX("chest_open")
        
        // Add item to inventory using the GameEngine method
        let pearl = Item(id: "pearl", name: "Shiny Pearl", imageName: "pearl")
        GameEngine.shared.addItemToInventory(pearl)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // Move character to touch location
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let moveAction = SKAction.move(to: location, duration: 1.0)
        fishCharacter.run(moveAction)
    }
}
