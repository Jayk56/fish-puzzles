//
//  CharacterAnimationComponent.swift
//  fish-puzzles
//
//  Manages character sprite animations
//

import SpriteKit

class CharacterAnimationComponent: Component {
    enum AnimationState {
        case idle
        case swimming
        case success
        case confused
    }
    
    private var animations: [AnimationState: SKAction] = [:]
    private var currentState: AnimationState = .idle
    private var spriteFrames: [SKTexture] = []
    
    override func didAddToEntity() {
        super.didAddToEntity()
        setupAnimations()
    }
    
    private func setupAnimations() {
        // Load all frames from sprite sheet
        spriteFrames = AssetManager.shared.loadTexturesFromSpriteSheet(
            named: "sprite-sheet-blue-fish",
            rows: 3,
            columns: 3
        )
        
        guard spriteFrames.count >= 9 else {
            print("⚠️ Failed to load fish sprite frames")
            return
        }
        
        // Idle animation: frames 0→1→2→1 (eye blink cycle)
        let idleTextures = [
            spriteFrames[0],
            spriteFrames[1],
            spriteFrames[2],
            spriteFrames[1]
        ]
        animations[.idle] = SKAction.repeatForever(
            SKAction.animate(with: idleTextures, timePerFrame: 0.8)
        )
        
        // Swimming animation: frames 3→4→5→4 (swimming motion)
        let swimTextures = [
            spriteFrames[3],
            spriteFrames[4],
            spriteFrames[5],
            spriteFrames[4]
        ]
        animations[.swimming] = SKAction.animate(with: swimTextures, timePerFrame: 0.15)
        
        // Success animation: frame 8 (happy with sparkles)
        animations[.success] = SKAction.animate(with: [spriteFrames[8]], timePerFrame: 1.0)
        
        // Confused animation: frames 6→7 alternating (puzzled with question bubble)
        let confusedTextures = [
            spriteFrames[6],
            spriteFrames[7]
        ]
        animations[.confused] = SKAction.animate(with: confusedTextures, timePerFrame: 0.5)
        
        // Start with idle animation
        playAnimation(.idle)
    }
    
    func playAnimation(_ state: AnimationState, repeatCount: Int = 0) {
        guard currentState != state || state == .success || state == .confused,
              var action = animations[state],
              let sprite = entity?.node as? SKSpriteNode else { return }
        
        // Remove current animation
        sprite.removeAction(forKey: "animation")
        
        // Apply repeat count if specified
        if repeatCount > 0 && (state == .swimming || state == .confused) {
            action = SKAction.repeat(action, count: repeatCount)
        }
        
        // Run new animation
        if state == .success || state == .confused {
            // For one-shot animations, chain back to idle
            let returnToIdle = SKAction.run { [weak self] in
                self?.playAnimation(.idle)
            }
            let sequence = SKAction.sequence([action, returnToIdle])
            sprite.run(sequence, withKey: "animation")
        } else {
            sprite.run(action, withKey: "animation")
        }
        
        currentState = state
    }
    
    func faceDirection(movingTo targetPosition: CGPoint) {
        guard let sprite = entity?.node as? SKSpriteNode else { return }
        
        // Flip sprite based on movement direction
        if targetPosition.x < sprite.position.x {
            sprite.xScale = -abs(sprite.xScale) // Face left
        } else {
            sprite.xScale = abs(sprite.xScale) // Face right
        }
    }
    
    func getCurrentFrame() -> SKTexture? {
        guard !spriteFrames.isEmpty else { return nil }
        return spriteFrames[0] // Default frame
    }
}