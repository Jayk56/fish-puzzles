//
//  MovementSystem.swift
//  fish-puzzles
//
//  Handles moving the player entity only, keeping props static
//

import SpriteKit

final class MovementSystem {
    weak var scene: BaseGameScene?
    weak var playerEntity: Entity?
    
    init(scene: BaseGameScene) {
        self.scene = scene
    }
    
    func movePlayer(to point: CGPoint, completion: (() -> Void)? = nil) {
        guard let scene = scene,
              let player = playerEntity,
              let node = player.node as? SKSpriteNode else { return }
        
        // Constrain movement to safe area
        let safeArea = scene.safeGameplayArea
        let target = CGPoint(
            x: max(safeArea.minX + node.size.width/2, min(safeArea.maxX - node.size.width/2, point.x)),
            y: max(safeArea.minY + node.size.height/2, min(safeArea.maxY - node.size.height/2, point.y))
        )
        
        // Face the correct direction (if component exists)
        if let anim = player.get(CharacterAnimationComponent.self) {
            anim.faceDirection(movingTo: target)
        }
        
        // Calculate distance and duration
        let distance = hypot(target.x - node.position.x, target.y - node.position.y)
        let duration = Double(distance / 200.0)
        
        // Play swimming animation for the duration of movement
        if let anim = player.get(CharacterAnimationComponent.self) {
            let swimRepeats = Int(ceil(duration / 0.6))
            anim.playAnimation(.swimming, repeatCount: swimRepeats)
        }
        
        let moveAction = SKAction.move(to: target, duration: duration)
        node.run(moveAction) { [weak player] in
            if let anim = player?.get(CharacterAnimationComponent.self) {
                anim.playAnimation(.idle)
            }
            completion?()
        }
    }
}
