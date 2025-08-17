//
//  Location1Scene.swift
//  fish-puzzles
//
//  First location in the game
//

import SpriteKit

class Location1Scene: BaseGameScene {
    private var fishCharacter: SKSpriteNode!
    private var fishEntity: Entity!
    private var animationComponent: CharacterAnimationComponent!
    
    override func setupScene() {
        super.setupScene()
        
        print("🏝️ Setting up Location1Scene...")
        
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
        
        print("✅ Location1Scene ready! Tap to move fish, tap treasure chest to collect pearl.")
    }
    
    private func setupCharacter() {
        // Create fish entity with sprite
        fishEntity = Entity()
        
        // Load first frame as initial texture
        let frames = AssetManager.shared.loadTexturesFromSpriteSheet(
            named: "sprite-sheet-blue-fish",
            rows: 3,
            columns: 3
        )
        
        if !frames.isEmpty {
            fishCharacter = SKSpriteNode(texture: frames[0])
            fishCharacter.size = CGSize(width: 80, height: 60)
        } else {
            // Fallback to colored rectangle if sprite sheet fails
            fishCharacter = SKSpriteNode(color: .orange, size: CGSize(width: 80, height: 60))
            print("⚠️ Using fallback fish sprite")
        }
        
        fishCharacter.position = CGPoint(x: size.width * 0.2, y: size.height * 0.5)
        fishCharacter.name = "player"
        addChild(fishCharacter)
        
        // Connect entity to sprite
        fishEntity.node = fishCharacter
        
        // Add animation component
        animationComponent = CharacterAnimationComponent()
        fishEntity.add(animationComponent)
        
        // Add entity to scene's entity list
        entities.append(fishEntity)
        
        // Add slight floating animation
        let floatUp = SKAction.moveBy(x: 0, y: 10, duration: 2)
        let floatDown = SKAction.moveBy(x: 0, y: -10, duration: 2)
        let sequence = SKAction.sequence([floatUp, floatDown])
        fishCharacter.run(SKAction.repeatForever(sequence), withKey: "floating")
    }
    
    private func setupHotspots() {
        // Add visible treasure chest sprite
        let chestSprite = SKSpriteNode(color: .brown, size: CGSize(width: 100, height: 80))
        chestSprite.position = CGPoint(x: size.width * 0.7, y: size.height * 0.3)
        chestSprite.name = "treasureChest"
        addChild(chestSprite)
        
        // Add golden trim to make it look like a chest
        let chestTrim = SKSpriteNode(color: .systemYellow, size: CGSize(width: 100, height: 10))
        chestTrim.position = CGPoint(x: 0, y: 30)
        chestSprite.addChild(chestTrim)
        
        // Add lock/keyhole visual
        let lock = SKShapeNode(circleOfRadius: 8)
        lock.fillColor = .black
        lock.position = CGPoint(x: 0, y: 0)
        chestSprite.addChild(lock)
        
        // Register hotspot for interaction
        let chestHotspot = Hotspot(
            id: "treasure_chest",
            frame: CGRect(x: size.width * 0.7 - 50, y: size.height * 0.3 - 40, width: 100, height: 80),
            action: { [weak self] in
                self?.openTreasureChest()
            }
        )
        interactionSystem.registerHotspot(chestHotspot)
        
        // Add a locked door as example of confused animation trigger
        let doorSprite = SKSpriteNode(color: .darkGray, size: CGSize(width: 80, height: 120))
        doorSprite.position = CGPoint(x: size.width * 0.9, y: size.height * 0.5)
        doorSprite.name = "lockedDoor"
        addChild(doorSprite)
        
        // Add door handle
        let handle = SKShapeNode(circleOfRadius: 5)
        handle.fillColor = .systemYellow
        handle.position = CGPoint(x: -20, y: 0)
        doorSprite.addChild(handle)
        
        // Register locked door hotspot
        let doorHotspot = Hotspot(
            id: "locked_door",
            frame: CGRect(x: size.width * 0.9 - 40, y: size.height * 0.5 - 60, width: 80, height: 120),
            action: { [weak self] in
                self?.tryLockedDoor()
            }
        )
        interactionSystem.registerHotspot(doorHotspot)
    }
    
    private func tryLockedDoor() {
        print("🔒 The door is locked! Fish looks confused...")
        showConfusedAnimation()
        AudioManager.shared.playSFX("locked")
    }
    
    private func openTreasureChest() {
        print("🎉 Opening treasure chest!")
        AudioManager.shared.playSFX("chest_open")
        
        // Play success animation on fish
        animationComponent.playAnimation(.success)
        
        // Add item to inventory using the GameEngine method
        let pearl = Item(id: "pearl", name: "Shiny Pearl", imageName: "pearl")
        GameEngine.shared.addItemToInventory(pearl)
        print("✨ Added Shiny Pearl to inventory!")
        
        // Visual feedback - chest opens
        if let chest = childNode(withName: "treasureChest") {
            // Animate chest opening
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.5)
            let sequence = SKAction.sequence([scaleUp, scaleDown, fadeOut])
            chest.run(sequence)
            
            // Show pearl emerging from chest
            let pearlSprite = SKShapeNode(circleOfRadius: 20)
            pearlSprite.fillColor = .white
            pearlSprite.strokeColor = .systemPink
            pearlSprite.lineWidth = 2
            pearlSprite.position = chest.position
            addChild(pearlSprite)
            
            let moveUp = SKAction.moveBy(x: 0, y: 100, duration: 1.0)
            let fadeAway = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let pearlSequence = SKAction.sequence([moveUp, fadeAway, remove])
            pearlSprite.run(pearlSequence)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // Move character to touch location
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Face the correct direction
        animationComponent.faceDirection(movingTo: location)
        
        // Calculate distance for accurate animation duration
        let distance = hypot(location.x - fishCharacter.position.x, 
                           location.y - fishCharacter.position.y)
        let duration = Double(distance / 200.0) // Speed: 200 points per second
        
        // Play swimming animation for the duration of movement
        let swimRepeats = Int(ceil(duration / 0.6)) // Each swim cycle is ~0.6 seconds
        animationComponent.playAnimation(.swimming, repeatCount: swimRepeats)
        
        // Move the fish
        let moveAction = SKAction.move(to: location, duration: duration)
        fishCharacter.run(moveAction) { [weak self] in
            // Return to idle when movement completes
            self?.animationComponent.playAnimation(.idle)
        }
    }
    
    // Add a method to show confused animation when trying locked items
    private func showConfusedAnimation() {
        animationComponent.playAnimation(.confused, repeatCount: 2)
    }
}
