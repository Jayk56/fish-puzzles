//
//  ItemCursor.swift
//  fish-puzzles
//
//  Visual cursor that follows touch when item is selected
//

import SpriteKit

class ItemCursor: SKNode {
    private var itemSprite: SKSpriteNode?
    private var glowEffect: SKEffectNode?
    private var validIndicator: SKShapeNode?
    private var invalidIndicator: SKShapeNode?
    private var currentItem: Item?
    
    override init() {
        super.init()
        setupCursor()
        zPosition = 1000
        isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCursor() {
        glowEffect = SKEffectNode()
        glowEffect?.shouldRasterize = true
        addChild(glowEffect!)
        
        validIndicator = createIndicator(color: .systemGreen)
        validIndicator?.isHidden = true
        addChild(validIndicator!)
        
        invalidIndicator = createIndicator(color: .systemRed)
        invalidIndicator?.isHidden = true
        addChild(invalidIndicator!)
    }
    
    private func createIndicator(color: UIColor) -> SKShapeNode {
        let circle = SKShapeNode(circleOfRadius: 40)
        circle.strokeColor = color
        circle.lineWidth = 3
        circle.glowWidth = 5
        circle.fillColor = color.withAlphaComponent(0.2)
        circle.zPosition = -1
        return circle
    }
    
    func attachItem(_ item: Item) {
        currentItem = item
        
        itemSprite?.removeFromParent()
        
        itemSprite = SKSpriteNode(imageNamed: item.imageName)
        itemSprite?.size = CGSize(width: 60, height: 60)
        itemSprite?.zPosition = 1
        
        if let sprite = itemSprite {
            glowEffect?.addChild(sprite)
        }
        
        let floatAction = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.5),
            SKAction.moveBy(x: 0, y: -5, duration: 0.5)
        ])
        run(SKAction.repeatForever(floatAction))
        
        alpha = 0.9
        isHidden = false
    }
    
    func detachItem() {
        currentItem = nil
        itemSprite?.removeFromParent()
        itemSprite = nil
        removeAllActions()
        isHidden = true
    }
    
    func updatePosition(_ position: CGPoint) {
        self.position = CGPoint(x: position.x, y: position.y + 30)
    }
    
    func showValidTarget() {
        validIndicator?.isHidden = false
        invalidIndicator?.isHidden = true
        
        validIndicator?.removeAllActions()
        validIndicator?.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.3),
            SKAction.scale(to: 0.9, duration: 0.3)
        ])))
        
        itemSprite?.run(SKAction.scale(to: 1.2, duration: 0.1))
    }
    
    func showInvalidTarget() {
        validIndicator?.isHidden = true
        invalidIndicator?.isHidden = false
        
        invalidIndicator?.removeAllActions()
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.1),
            SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        ])
        invalidIndicator?.run(SKAction.repeat(shake, count: 2))
        
        itemSprite?.run(SKAction.scale(to: 0.8, duration: 0.1))
    }
    
    func showNeutral() {
        validIndicator?.isHidden = true
        invalidIndicator?.isHidden = true
        validIndicator?.removeAllActions()
        invalidIndicator?.removeAllActions()
        
        itemSprite?.run(SKAction.scale(to: 1.0, duration: 0.1))
    }
    
    func animateUse(success: Bool, completion: @escaping () -> Void) {
        if success {
            let successAnimation = SKAction.sequence([
                SKAction.scale(to: 1.5, duration: 0.2),
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 0.1, duration: 0.3)
                ])
            ])
            
            run(successAnimation) {
                self.detachItem()
                completion()
            }
            
            createSuccessParticles()
        } else {
            let failAnimation = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -20, duration: 0.1),
                SKAction.moveBy(x: 0, y: 20, duration: 0.1),
                SKAction.moveBy(x: -10, y: 0, duration: 0.05),
                SKAction.moveBy(x: 20, y: 0, duration: 0.1),
                SKAction.moveBy(x: -10, y: 0, duration: 0.05)
            ])
            
            run(failAnimation) {
                completion()
            }
        }
    }
    
    private func createSuccessParticles() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleBirthRate = 100
        emitter.particleLifetime = 0.5
        emitter.particleScale = 0.3
        emitter.particleScaleSpeed = -0.6
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 50
        emitter.emissionAngleRange = .pi * 2
        emitter.particleColor = .systemYellow
        emitter.position = .zero
        emitter.zPosition = 10
        
        addChild(emitter)
        
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }
}