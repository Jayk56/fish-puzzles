//
//  BackgroundStyler.swift
//  fish-puzzles
//
//  Provides themed background styles for non-safe areas
//

import SpriteKit

class BackgroundStyler {
    static let shared = BackgroundStyler()
    
    enum Theme {
        case underwater
        case coral
        case deepSea
        case tropical
        case custom(style: SafeAreaManager.BorderStyle)
        
        var borderStyle: SafeAreaManager.BorderStyle {
            switch self {
            case .underwater:
                // Use solid color for better blending
                return .solid(color: UIColor(red: 0.0, green: 0.25, blue: 0.45, alpha: 1.0))
                
            case .coral:
                // Use solid coral color
                return .solid(color: UIColor(red: 1.0, green: 0.45, blue: 0.45, alpha: 1.0))
                
            case .deepSea:
                // Use solid deep sea color
                return .solid(color: UIColor(red: 0.0, green: 0.08, blue: 0.18, alpha: 1.0))
                
            case .tropical:
                // Use solid tropical color that matches the play area
                return .solid(color: UIColor(red: 0.0, green: 0.7, blue: 0.85, alpha: 1.0))
                
            case .custom(let style):
                return style
            }
        }
    }
    
    private init() {}
    
    /// Apply themed styling to a scene's non-safe areas
    func applyTheme(_ theme: Theme, to scene: SKScene) {
        // Remove existing border styling if present
        scene.childNode(withName: "borderContainer")?.removeFromParent()
        
        // Create and add new styled borders
        let borders = SafeAreaManager.shared.createStyledBorders(
            for: scene,
            style: theme.borderStyle
        )
        scene.addChild(borders)
        
        // Add animated effects for certain themes
        addThemeEffects(theme: theme, to: borders)
    }
    
    /// Add bubble or particle effects to enhance the theme
    private func addThemeEffects(theme: Theme, to borderContainer: SKNode) {
        switch theme {
        case .underwater:
            addBubbleEffect(to: borderContainer)
        case .deepSea:
            addFloatingParticles(to: borderContainer, color: .cyan, scale: 0.3)
        case .tropical:
            addFloatingParticles(to: borderContainer, color: .yellow, scale: 0.5)
        default:
            break
        }
    }
    
    private func addBubbleEffect(to container: SKNode) {
        guard let bottomBorder = container.childNode(withName: "bottomBorder") else { return }
        
        let bubbleEmitter = SKEmitterNode()
        bubbleEmitter.particleTexture = createCircleTexture(radius: 10)
        bubbleEmitter.particleBirthRate = 2
        bubbleEmitter.particleLifetime = 4
        bubbleEmitter.particleScale = 0.1
        bubbleEmitter.particleScaleRange = 0.05
        bubbleEmitter.particleScaleSpeed = 0.02
        bubbleEmitter.particleAlpha = 0.6
        bubbleEmitter.particleAlphaSpeed = -0.15
        bubbleEmitter.particleSpeed = 30
        bubbleEmitter.particleSpeedRange = 10
        bubbleEmitter.emissionAngle = CGFloat.pi / 2
        bubbleEmitter.emissionAngleRange = CGFloat.pi / 6
        bubbleEmitter.particlePositionRange = CGVector(dx: bottomBorder.frame.width, dy: 0)
        bubbleEmitter.position = CGPoint(x: 0, y: -bottomBorder.frame.height / 2)
        bubbleEmitter.zPosition = 10
        bubbleEmitter.name = "bubbleEffect"
        
        bottomBorder.addChild(bubbleEmitter)
    }
    
    private func addFloatingParticles(to container: SKNode, color: UIColor, scale: CGFloat) {
        guard let bottomBorder = container.childNode(withName: "bottomBorder") else { return }
        
        let particleEmitter = SKEmitterNode()
        particleEmitter.particleTexture = createStarTexture()
        particleEmitter.particleBirthRate = 1
        particleEmitter.particleLifetime = 6
        particleEmitter.particleScale = scale
        particleEmitter.particleScaleRange = scale * 0.3
        particleEmitter.particleColor = color
        particleEmitter.particleAlpha = 0.7
        particleEmitter.particleAlphaSpeed = -0.1
        particleEmitter.particleSpeed = 20
        particleEmitter.particleSpeedRange = 10
        particleEmitter.emissionAngle = 0
        particleEmitter.emissionAngleRange = CGFloat.pi * 2
        particleEmitter.particlePositionRange = CGVector(dx: bottomBorder.frame.width, dy: 20)
        particleEmitter.position = CGPoint(x: 0, y: -bottomBorder.frame.height / 2 + 20)
        particleEmitter.zPosition = 10
        particleEmitter.name = "particleEffect"
        
        bottomBorder.addChild(particleEmitter)
    }
    
    private func createCircleTexture(radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            return SKTexture(image: image)
        }
        return SKTexture()
    }
    
    private func createStarTexture() -> SKTexture {
        let size = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        // Draw a simple star shape
        let center = CGPoint(x: 10, y: 10)
        let outerRadius: CGFloat = 10
        let innerRadius: CGFloat = 4
        let points = 5
        
        context.setFillColor(UIColor.white.cgColor)
        context.beginPath()
        
        for i in 0..<points * 2 {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = CGFloat(i) * CGFloat.pi / CGFloat(points)
            let x = center.x + radius * cos(angle - CGFloat.pi / 2)
            let y = center.y + radius * sin(angle - CGFloat.pi / 2)
            
            if i == 0 {
                context.move(to: CGPoint(x: x, y: y))
            } else {
                context.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        context.closePath()
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            return SKTexture(image: image)
        }
        return SKTexture()
    }
}