//
//  CloseButton.swift
//  fish-puzzles
//
//  Close button for overlays with proper touch handling
//

import SpriteKit

class CloseButton: SKSpriteNode {
    var onTap: (() -> Void)?
    private var xLabel: SKLabelNode!
    
    init(size: CGSize = CGSize(width: 40, height: 40)) {
        super.init(texture: nil, color: .red, size: size)
        
        // Enable touch handling
        isUserInteractionEnabled = true
        name = "closeButton"
        
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        // Add X label
        xLabel = SKLabelNode(text: "✕")
        xLabel.fontSize = 24
        xLabel.fontName = "AvenirNext-Bold"
        xLabel.verticalAlignmentMode = .center
        xLabel.zPosition = 1
        addChild(xLabel)
        
        // Add border
        let border = SKShapeNode(rectOf: size, cornerRadius: 5)
        border.strokeColor = .white
        border.lineWidth = 2
        border.zPosition = 0
        addChild(border)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Visual feedback
        run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.05)
        ]))
        
        // Trigger close action
        onTap?()
        
        // Play sound
        AudioManager.shared.playSFX("tap")
    }
}