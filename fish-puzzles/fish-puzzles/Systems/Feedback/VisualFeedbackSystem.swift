//
//  VisualFeedbackSystem.swift
//  fish-puzzles
//
//  Provides visual feedback and affordances for interactions
//

import SpriteKit

class VisualFeedbackSystem {
    static let shared = VisualFeedbackSystem()
    
    private var activeEffects: Set<SKNode> = []
    
    private init() {}
    
    func showHotspotGlow(on node: SKNode, level: GlowLevel) {
        removeEffect(from: node, named: "hotspotGlow")
        
        let glow = createGlowEffect(
            size: node.frame.size,
            color: level.color,
            intensity: level.intensity
        )
        glow.name = "hotspotGlow"
        node.addChild(glow)
        
        switch level {
        case .subtle:
            animateSubtleGlow(glow)
        case .moderate:
            animateModerateGlow(glow)
        case .strong:
            animateStrongGlow(glow)
        case .urgent:
            animateUrgentGlow(glow)
        }
        
        activeEffects.insert(glow)
    }
    
    func showInteractionFeedback(at point: CGPoint, type: InteractionType) {
        guard let scene = getCurrentScene() else { return }
        
        let feedback = createInteractionFeedback(type: type)
        feedback.position = point
        feedback.zPosition = 1500
        scene.addChild(feedback)
        
        animateInteractionFeedback(feedback, type: type)
        activeEffects.insert(feedback)
    }
    
    func showItemPickup(item: Item, from: CGPoint, to: CGPoint) {
        guard let scene = getCurrentScene() else { return }
        
        let itemVisual = SKSpriteNode(imageNamed: item.imageName)
        itemVisual.size = CGSize(width: 50, height: 50)
        itemVisual.position = from
        itemVisual.zPosition = 2000
        scene.addChild(itemVisual)
        
        let path = createCurvedPath(from: from, to: to)
        let followPath = SKAction.follow(path, asOffset: false, orientToPath: false, duration: 0.5)
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        
        itemVisual.run(SKAction.sequence([
            scaleUp,
            SKAction.group([followPath, scaleDown]),
            fadeOut,
            SKAction.removeFromParent()
        ]))
        
        createPickupParticles(at: from)
        AudioManager.shared.playSFX("item_pickup")
    }
    
    func showValidTarget(node: SKNode) {
        removeEffect(from: node, named: "targetIndicator")
        
        let indicator = createTargetIndicator(color: .systemGreen)
        indicator.name = "targetIndicator"
        node.addChild(indicator)
        
        indicator.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.3),
            SKAction.scale(to: 0.9, duration: 0.3)
        ])))
        
        activeEffects.insert(indicator)
    }
    
    func showInvalidTarget(node: SKNode) {
        let flash = SKShapeNode(rect: node.frame)
        flash.fillColor = .systemRed
        flash.alpha = 0.5
        flash.zPosition = 100
        node.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
        
        node.run(SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.1),
            SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        ]))
        
        AudioManager.shared.playSFX("invalid_action")
    }
    
    func showSuccess(at point: CGPoint) {
        guard let scene = getCurrentScene() else { return }
        
        let burst = createSuccessBurst()
        burst.position = point
        burst.zPosition = 2000
        scene.addChild(burst)
        
        burst.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        AudioManager.shared.playSFX("success")
    }
    
    func clearAllEffects() {
        activeEffects.forEach { $0.removeFromParent() }
        activeEffects.removeAll()
    }
    
    private func createGlowEffect(size: CGSize, color: UIColor, intensity: CGFloat) -> SKEffectNode {
        let effect = SKEffectNode()
        
        let glow = SKShapeNode(rectOf: CGSize(
            width: size.width + 20,
            height: size.height + 20
        ), cornerRadius: 10)
        
        glow.strokeColor = color
        glow.lineWidth = 2 * intensity
        glow.glowWidth = 10 * intensity
        glow.fillColor = color.withAlphaComponent(0.1 * intensity)
        
        effect.addChild(glow)
        effect.shouldRasterize = true
        
        return effect
    }
    
    private func createInteractionFeedback(type: InteractionType) -> SKNode {
        let container = SKNode()
        
        let icon = SKLabelNode(text: type.icon)
        icon.fontSize = 30
        icon.fontName = "AvenirNext-Bold"
        container.addChild(icon)
        
        let circle = SKShapeNode(circleOfRadius: 25)
        circle.strokeColor = type.color
        circle.lineWidth = 2
        circle.fillColor = type.color.withAlphaComponent(0.2)
        circle.zPosition = -1
        container.addChild(circle)
        
        return container
    }
    
    private func createTargetIndicator(color: UIColor) -> SKNode {
        let indicator = SKShapeNode(circleOfRadius: 30)
        indicator.strokeColor = color
        indicator.lineWidth = 3
        indicator.glowWidth = 5
        indicator.fillColor = .clear
        return indicator
    }
    
    private func createCurvedPath(from: CGPoint, to: CGPoint) -> CGPath {
        let path = CGMutablePath()
        path.move(to: from)
        
        let controlPoint = CGPoint(
            x: (from.x + to.x) / 2,
            y: max(from.y, to.y) + 50
        )
        
        path.addQuadCurve(to: to, control: controlPoint)
        return path
    }
    
    private func createPickupParticles(at point: CGPoint) {
        guard let scene = getCurrentScene() else { return }
        
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleBirthRate = 50
        emitter.particleLifetime = 0.5
        emitter.particleScale = 0.2
        emitter.particleScaleSpeed = -0.4
        emitter.particleSpeed = 80
        emitter.emissionAngleRange = .pi * 2
        emitter.particleColor = .systemYellow
        emitter.position = point
        emitter.zPosition = 1500
        
        scene.addChild(emitter)
        
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    private func createSuccessBurst() -> SKNode {
        let container = SKNode()
        
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4
            let star = createStar()
            star.position = .zero
            
            let moveAction = SKAction.move(
                by: CGVector(dx: cos(angle) * 100, dy: sin(angle) * 100),
                duration: 0.5
            )
            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            let scaleAction = SKAction.scale(to: 0.1, duration: 0.5)
            
            star.run(SKAction.group([moveAction, fadeAction, scaleAction]))
            container.addChild(star)
        }
        
        return container
    }
    
    private func createStar() -> SKShapeNode {
        let star = SKShapeNode()
        let path = CGMutablePath()
        
        let points = 5
        let radius: CGFloat = 10
        let innerRadius: CGFloat = 5
        
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points)
            let r = i % 2 == 0 ? radius : innerRadius
            let x = cos(angle) * r
            let y = sin(angle) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        star.path = path
        star.fillColor = .systemYellow
        star.strokeColor = .clear
        
        return star
    }
    
    private func animateSubtleGlow(_ node: SKNode) {
        node.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 1.0),
            SKAction.fadeAlpha(to: 0.6, duration: 1.0)
        ])))
    }
    
    private func animateModerateGlow(_ node: SKNode) {
        node.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 0.8, duration: 0.5),
                SKAction.scale(to: 1.05, duration: 0.5)
            ]),
            SKAction.group([
                SKAction.fadeAlpha(to: 0.4, duration: 0.5),
                SKAction.scale(to: 0.95, duration: 0.5)
            ])
        ])))
    }
    
    private func animateStrongGlow(_ node: SKNode) {
        node.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.3),
                SKAction.scale(to: 1.1, duration: 0.3)
            ]),
            SKAction.group([
                SKAction.fadeAlpha(to: 0.5, duration: 0.3),
                SKAction.scale(to: 0.9, duration: 0.3)
            ])
        ])))
    }
    
    private func animateUrgentGlow(_ node: SKNode) {
        node.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.1),
            SKAction.fadeAlpha(to: 0.2, duration: 0.1)
        ])))
        
        let arrow = createArrowPointing(to: node)
        node.parent?.addChild(arrow)
    }
    
    private func createArrowPointing(to node: SKNode) -> SKNode {
        let arrow = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 20))
        path.addLine(to: CGPoint(x: -10, y: 0))
        path.addLine(to: CGPoint(x: 10, y: 0))
        path.closeSubpath()
        
        arrow.path = path
        arrow.fillColor = .systemYellow
        arrow.position = CGPoint(x: node.position.x, y: node.position.y + 50)
        
        arrow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: -10, duration: 0.5),
            SKAction.moveBy(x: 0, y: 10, duration: 0.5)
        ])))
        
        return arrow
    }
    
    private func animateInteractionFeedback(_ node: SKNode, type: InteractionType) {
        node.setScale(0)
        node.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    private func removeEffect(from node: SKNode, named name: String) {
        if let effect = node.childNode(withName: name) {
            activeEffects.remove(effect)
            effect.removeFromParent()
        }
    }
    
    private func getCurrentScene() -> SKScene? {
        return (UIApplication.shared.keyWindow?.rootViewController?.view as? SKView)?.scene
    }
}

enum GlowLevel {
    case subtle
    case moderate
    case strong
    case urgent
    
    var color: UIColor {
        switch self {
        case .subtle: return .systemYellow.withAlphaComponent(0.5)
        case .moderate: return .systemYellow.withAlphaComponent(0.7)
        case .strong: return .systemOrange
        case .urgent: return .systemRed
        }
    }
    
    var intensity: CGFloat {
        switch self {
        case .subtle: return 0.3
        case .moderate: return 0.6
        case .strong: return 0.9
        case .urgent: return 1.0
        }
    }
}

enum InteractionType {
    case look
    case take
    case use
    case talk
    case move
    case blocked
    
    var icon: String {
        switch self {
        case .look: return "👁"
        case .take: return "✋"
        case .use: return "⚙️"
        case .talk: return "💬"
        case .move: return "👣"
        case .blocked: return "❌"
        }
    }
    
    var color: UIColor {
        switch self {
        case .look: return .systemBlue
        case .take: return .systemGreen
        case .use: return .systemOrange
        case .talk: return .systemPurple
        case .move: return .systemGray
        case .blocked: return .systemRed
        }
    }
}