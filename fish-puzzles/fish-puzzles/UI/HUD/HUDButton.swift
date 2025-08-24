//
//  HUDButton.swift
//  fish-puzzles
//
//  HUD button with proper touch handling
//

import SpriteKit

class HUDButton: SKNode {
    let buttonType: ButtonType
    var onTap: (() -> Void)?
    private var background: SKShapeNode!
    private var iconLabel: SKLabelNode!
    private var border: SKShapeNode!
    private var buttonSize: CGSize
    
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
        self.buttonSize = size
        super.init()
        
        // Enable touch handling
        isUserInteractionEnabled = true
        
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        // Add rounded background
        background = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
        background.fillColor = UIColor(white: 0.2, alpha: 0.7)
        background.strokeColor = .clear
        background.zPosition = 0
        addChild(background)
        
        // Add border
        border = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
        border.strokeColor = .white
        border.lineWidth = 2
        border.fillColor = .clear
        border.zPosition = 1
        addChild(border)
        
        // Add icon
        iconLabel = SKLabelNode(text: buttonType.icon)
        iconLabel.fontSize = min(28, buttonSize.height * 0.56)
        iconLabel.verticalAlignmentMode = .center
        iconLabel.zPosition = 2
        addChild(iconLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Check if touch is within the button bounds
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if !background.contains(location) { return }
        
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

    /// Resize the button visuals to a new size (keeps position)
    func resize(to size: CGSize) {
        buttonSize = size
        background.path = CGPath(roundedRect: CGRect(origin: .zero, size: size).offsetBy(dx: -size.width/2, dy: -size.height/2), cornerWidth: 10, cornerHeight: 10, transform: nil)
        border.path = CGPath(roundedRect: CGRect(origin: .zero, size: size).offsetBy(dx: -size.width/2, dy: -size.height/2), cornerWidth: 10, cornerHeight: 10, transform: nil)
        iconLabel.fontSize = min(28, size.height * 0.56)
    }
}
