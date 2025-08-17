//
//  HUDButton.swift
//  fish-puzzles
//
//  HUD button with proper touch handling
//

import SpriteKit

class HUDButton: SKSpriteNode {
    let buttonType: ButtonType
    var onTap: (() -> Void)?
    private var iconLabel: SKLabelNode!
    private var border: SKShapeNode!
    
    enum ButtonType {
        case inventory
        case map
        case settings
        case hint
        
        var icon: String {
            switch self {
            case .inventory: return "🎒"
            case .map: return "🗺"
            case .settings: return "⚙️"
            case .hint: return "💡"
            }
        }
    }
    
    init(type: ButtonType, size: CGSize = CGSize(width: 50, height: 50)) {
        self.buttonType = type
        super.init(texture: nil, color: UIColor(white: 0.2, alpha: 0.7), size: size)
        
        // Enable touch handling
        isUserInteractionEnabled = true
        
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        // Add border
        border = SKShapeNode(rectOf: size, cornerRadius: 10)
        border.strokeColor = .white
        border.lineWidth = 2
        border.zPosition = 1
        addChild(border)
        
        // Add icon
        iconLabel = SKLabelNode(text: buttonType.icon)
        iconLabel.fontSize = 28
        iconLabel.verticalAlignmentMode = .center
        iconLabel.zPosition = 2
        addChild(iconLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Visual feedback
        run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.05)
        ]))
        
        // Trigger action
        onTap?()
        
        // Play sound
        AudioManager.shared.playSFX("tap")
    }
    
    func setHighlighted(_ highlighted: Bool) {
        if highlighted {
            border.strokeColor = .cyan
            border.glowWidth = 5
        } else {
            border.strokeColor = .white
            border.glowWidth = 0
        }
    }
}