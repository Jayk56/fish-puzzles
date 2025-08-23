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
    private var chestEntity: Entity!
    
    override func setupScene() {
        // Set the background theme before calling super
        backgroundTheme = .tropical
        
        super.setupScene()
        
        // Add accessibility identifier for UI testing
        isAccessibilityElement = true
        accessibilityLabel = "Location1Scene"
        
        print("🏝️ Setting up Location1Scene...")
        
        // Set scene scaling for landscape
        scaleMode = .aspectFill
        
        // Background - match the tropical theme colors for seamless blend
        // Tropical theme uses cyan-like colors, so we'll match that
        let background = createSafeBackground(color: UIColor(red: 0.0, green: 0.7, blue: 0.85, alpha: 1.0))
        addChild(background)
        
        // Enable debug mode to visualize safe areas (remove in production)
        #if DEBUG
        showSafeAreaDebug = true
        #endif
        
        // Add fish character
        setupCharacter()
        
        // Setup content and hotspots (via SceneFactory if available)
        setupContentFromDefinition()
        
        // Play underwater ambience
        AudioManager.shared.playMusic("underwater_ambience")
        
        print("✅ Location1Scene ready! Tap to move fish, tap treasure chest to collect pearl.")
    }

    override func getPlayerPosition() -> CGPoint? {
        return fishCharacter?.position
    }
    
    override func setupHUD() {
        super.setupHUD()
        
        // Buttons are now in the persistent inventory bar
        // Override setupPersistentButtons if you need custom button behavior
    }
    
    override func setupPersistentButtons() {
        super.setupPersistentButtons()
        
        // Customize hint button behavior for this scene
        guard let inventoryBar = hudManager?.inventoryBar else { return }
        
        // Find and update the hint button with scene-specific hint
        inventoryBar.persistentButtons.forEach { button in
            if button.buttonType == .hint {
                button.onTap = { [weak self] in
                    guard let hudManager = self?.hudManager else { return }
                    
                    if hudManager.isActive(.hint) {
                        hudManager.hide(.hint)
                        print("💡 Hiding hint")
                    } else {
                        if let hintOverlay = hudManager.overlays[.hint] as? HintOverlay {
                            hintOverlay.showHint("Try tapping on the treasure chest!", level: .subtle)
                        }
                        print("💡 Showing hint")
                    }
                }
            }
        }
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
        
        // Position fish in safe area (20% from left, 50% up)
        fishCharacter.position = safePosition(normalizedX: 0.2, normalizedY: 0.5)
        fishCharacter.name = "player"
        addChild(fishCharacter)
        
        // Connect entity to sprite
        fishEntity.node = fishCharacter
        
        // Add animation component
        animationComponent = CharacterAnimationComponent()
        fishEntity.add(animationComponent)
        
        // Register as the player for movement system
        movementSystem?.playerEntity = fishEntity
        
        // Add entity to scene's entity list
        entities.append(fishEntity)
        
        // Add slight floating animation
        let floatUp = SKAction.moveBy(x: 0, y: 10, duration: 2)
        let floatDown = SKAction.moveBy(x: 0, y: -10, duration: 2)
        let sequence = SKAction.sequence([floatUp, floatDown])
        fishCharacter.run(SKAction.repeatForever(sequence), withKey: "floating")
    }
    
    private func setupContentFromDefinition() {
        // Try to load JSON definition from bundle
        if let url = Bundle.main.url(forResource: "Location1", withExtension: "json", subdirectory: "Scenes") {
            do {
                let def = try SceneLoader.loadScene(from: url)
                let built = SceneFactory.build(from: def, into: self, interaction: interactionSystem)
                // Capture references to specific entities for custom visuals/logic
                if let chest = built.first(where: { $0.node?.name == "treasure_chest" }) {
                    chestEntity = chest
                    if let chestSprite = chest.node as? SKSpriteNode {
                        chestSprite.color = .brown
                        let chestTrim = SKSpriteNode(color: .systemYellow, size: CGSize(width: 100, height: 10))
                        chestTrim.position = CGPoint(x: 0, y: 30)
                        chestSprite.addChild(chestTrim)
                        let lock = SKShapeNode(circleOfRadius: 8)
                        lock.fillColor = .black
                        lock.position = CGPoint(x: 0, y: 0)
                        chestSprite.addChild(lock)
                    }
                }
                if let door = built.first(where: { $0.node?.name == "locked_door" }) {
                    if let doorSprite = door.node as? SKSpriteNode {
                        doorSprite.color = .darkGray
                        let handle = SKShapeNode(circleOfRadius: 5)
                        handle.fillColor = .systemYellow
                        handle.position = CGPoint(x: -20, y: 0)
                        doorSprite.addChild(handle)
                    }
                }
            } catch {
                print("⚠️ Failed to load scene definition: \(error). Falling back to inline setup.")
                setupFallbackContent()
            }
        } else {
            setupFallbackContent()
        }
        
        // Enable debug mode to visualize hotspots
        HotspotManager.shared.setDebugMode(true)
        HotspotManager.shared.createDebugNodes(in: self)
    }

    private func setupFallbackContent() {
        // Add visible treasure chest sprite
        let chestSprite = SKSpriteNode(color: .brown, size: CGSize(width: 100, height: 80))
        // Position chest in safe area (70% from left, 30% up)
        chestSprite.position = safePosition(normalizedX: 0.7, normalizedY: 0.3)
        chestSprite.name = "treasure_chest"
        addChild(chestSprite)
        
        // Create chest entity and link it to the sprite
        chestEntity = Entity()
        chestEntity.node = chestSprite
        entities.append(chestEntity)
        // Add a navigation zone so the player moves to a fixed approach point
        let chestApproach = NavigationZoneComponent.chest(at: chestSprite.position)
        chestEntity.add(chestApproach)
        
        // Add golden trim to make it look like a chest
        let chestTrim = SKSpriteNode(color: .systemYellow, size: CGSize(width: 100, height: 10))
        chestTrim.position = CGPoint(x: 0, y: 30)
        chestSprite.addChild(chestTrim)
        
        // Add lock/keyhole visual
        let lock = SKShapeNode(circleOfRadius: 8)
        lock.fillColor = .black
        lock.position = CGPoint(x: 0, y: 0)
        chestSprite.addChild(lock)
        
        // Register hotspot for interaction (using safe area position)
        let chestPosition = safePosition(normalizedX: 0.7, normalizedY: 0.3)
        let chestHotspot = Hotspot(
            id: "treasure_chest",
            type: .item,
            area: CGRect(x: chestPosition.x - 50, y: chestPosition.y - 40, width: 100, height: 80),
            description: "A locked treasure chest"
        )
        chestHotspot.delegate = self
        chestHotspot.node = chestSprite  // Link hotspot to its node
        interactionSystem.registerHotspot(chestHotspot)
        
        // Add a locked door as example of confused animation trigger
        let doorSprite = SKSpriteNode(color: .darkGray, size: CGSize(width: 80, height: 120))
        // Position door in safe area (90% from left, 50% up)
        doorSprite.position = safePosition(normalizedX: 0.9, normalizedY: 0.5)
        doorSprite.name = "locked_door"
        addChild(doorSprite)
        
        // Add door handle
        let handle = SKShapeNode(circleOfRadius: 5)
        handle.fillColor = .systemYellow
        handle.position = CGPoint(x: -20, y: 0)
        doorSprite.addChild(handle)
        
        // Register locked door hotspot
        // Register locked door hotspot (using safe area position)
        let doorPosition = safePosition(normalizedX: 0.9, normalizedY: 0.5)
        let doorHotspot = Hotspot(
            id: "locked_door",
            type: .door,
            area: CGRect(x: doorPosition.x - 40, y: doorPosition.y - 60, width: 80, height: 120),
            description: "A locked door"
        )
        doorHotspot.delegate = self
        interactionSystem.registerHotspot(doorHotspot)
    }
    
    private func tryLockedDoor() {
        print("🔒 The door is locked! Fish looks confused...")
        showConfusedAnimation()
        AudioManager.shared.playSFX("locked")
    }
    
    private func openTreasureChest() {
        print("🎉 Opening treasure chest!")
        
        // Create effects array using the new effect system
        var effects: [Effect] = []
        
        // Add sound effect
        effects.append(Effect(
            type: .playSound("chest_open"),
            target: nil,
            delay: 0
        ))
        
        // Play success animation on fish using the stored entity
        if fishEntity != nil {
            effects.append(Effect(
                type: .playAnimation("success"),
                target: fishEntity,
                delay: 0.2
            ))
        }
        
        // Animate chest opening with pearl rising using the stored chest entity
        if chestEntity != nil {
            effects.append(Effect(
                type: .playAnimation("pearl_rise"),
                target: chestEntity,
                delay: 0.3
            ))
            
            // Add sparkle particles
            effects.append(Effect(
                type: .showParticles("sparkle"),
                target: chestEntity,
                delay: 0.5
            ))
        }
        
        // Execute all effects through the interaction system
        interactionSystem.executeEffects(effects)
        
        // Add item to inventory
        let pearl = Item(id: "pearl", name: "Shiny Pearl", imageName: "pearl")
        GameEngine.shared.addItemToInventory(pearl)
        print("✨ Added Shiny Pearl to inventory!")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Thanks to isUserInteractionEnabled on HUD elements,
        // this method will only be called if no HUD element handled the touch.
        
        // Check if a game hotspot (chest, door) was touched
        if let handled = interactionSystem?.handleTouch(at: location), handled {
            return  // Don't move fish if interacting with something
        }
        
        // Nothing else handled the touch: move the player via movement system
        movementSystem?.movePlayer(to: location)
    }
    
    // Add a method to show confused animation when trying locked items
    private func showConfusedAnimation() {
        animationComponent.playAnimation(.confused, repeatCount: 2)
    }
}

// MARK: - HotspotDelegate
extension Location1Scene: HotspotDelegate {
    func hotspotDidActivate(_ hotspot: Hotspot) {
        // Handle activation if needed
    }
    
    func hotspotDidDeactivate(_ hotspot: Hotspot) {
        // Handle deactivation if needed
    }
    
    func hotspotDidTrigger(_ hotspot: Hotspot, with item: String?) {
        print("🎯 Hotspot triggered: \(hotspot.id) with item: \(item ?? "none")")
        switch hotspot.id {
        case "treasure_chest":
            openTreasureChest()
        case "locked_door":
            tryLockedDoor()
        default:
            break
        }
    }
}
