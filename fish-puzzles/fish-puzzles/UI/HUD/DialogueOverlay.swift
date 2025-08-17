//
//  DialogueOverlay.swift
//  fish-puzzles
//
//  Character dialogue overlay
//

import SpriteKit

class DialogueOverlay: BaseOverlay {
    private var dialogueBox: SKSpriteNode!
    private var characterName: SKLabelNode!
    private var dialogueText: SKLabelNode!
    private var continueIndicator: SKSpriteNode!
    private var characterPortrait: SKSpriteNode?
    
    private var currentText: String = ""
    private var displayedText: String = ""
    private var textTimer: TimeInterval = 0
    private let textSpeed: TimeInterval = 0.03
    private var isTextComplete = false
    
    init(size: CGSize) {
        super.init(layer: .dialogue, size: size)
        self.isModal = true
        self.dimBackground = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupOverlay() {
        setupDialogueBox()
        setupCharacterName()
        setupDialogueText()
        setupContinueIndicator()
    }
    
    private func setupDialogueBox() {
        let boxSize = CGSize(width: overlaySize.width * 0.85, height: 150)
        dialogueBox = SKSpriteNode(color: UIColor(white: 0.1, alpha: 0.95), size: boxSize)
        // Position at bottom of screen (container is now centered)
        dialogueBox.position = CGPoint(x: 0, y: -overlaySize.height/2 + boxSize.height/2 + 20)
        dialogueBox.zPosition = 0
        
        let border = SKShapeNode(rectOf: boxSize, cornerRadius: 15)
        border.strokeColor = .white
        border.lineWidth = 2
        border.zPosition = 1
        dialogueBox.addChild(border)
        
        addChild(dialogueBox)
    }
    
    private func setupCharacterName() {
        characterName = SKLabelNode(text: "")
        characterName.fontName = "AvenirNext-Bold"
        characterName.fontSize = 20
        characterName.horizontalAlignmentMode = .left
        characterName.position = CGPoint(
            x: -dialogueBox.size.width/2 + 20,
            y: dialogueBox.size.height/2 - 30
        )
        characterName.zPosition = 2
        dialogueBox.addChild(characterName)
    }
    
    private func setupDialogueText() {
        dialogueText = SKLabelNode(text: "")
        dialogueText.fontName = "AvenirNext-Regular"
        dialogueText.fontSize = 18
        dialogueText.horizontalAlignmentMode = .left
        dialogueText.verticalAlignmentMode = .top
        dialogueText.position = CGPoint(
            x: -dialogueBox.size.width/2 + 20,
            y: dialogueBox.size.height/2 - 60
        )
        dialogueText.preferredMaxLayoutWidth = dialogueBox.size.width - 40
        dialogueText.numberOfLines = 0
        dialogueText.zPosition = 2
        dialogueBox.addChild(dialogueText)
    }
    
    private func setupContinueIndicator() {
        continueIndicator = SKSpriteNode(color: .white, size: CGSize(width: 20, height: 20))
        continueIndicator.position = CGPoint(
            x: dialogueBox.size.width/2 - 30,
            y: -dialogueBox.size.height/2 + 30
        )
        continueIndicator.zPosition = 3
        continueIndicator.isHidden = true
        
        let triangle = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 10))
        path.addLine(to: CGPoint(x: -8, y: -5))
        path.addLine(to: CGPoint(x: 8, y: -5))
        path.closeSubpath()
        triangle.path = path
        triangle.fillColor = .white
        triangle.strokeColor = .clear
        continueIndicator.addChild(triangle)
        
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.5),
            SKAction.moveBy(x: 0, y: -5, duration: 0.5)
        ])
        continueIndicator.run(SKAction.repeatForever(bounce))
        
        dialogueBox.addChild(continueIndicator)
    }
    
    func showDialogue(character: String, text: String, portrait: SKTexture? = nil) {
        characterName.text = character
        currentText = text
        displayedText = ""
        dialogueText.text = ""
        textTimer = 0
        isTextComplete = false
        continueIndicator.isHidden = true
        
        if let portraitTexture = portrait {
            characterPortrait?.removeFromParent()
            characterPortrait = SKSpriteNode(texture: portraitTexture)
            characterPortrait?.size = CGSize(width: 80, height: 80)
            characterPortrait?.position = CGPoint(
                x: -dialogueBox.size.width/2 + 60,
                y: 0
            )
            characterPortrait?.zPosition = 2
            
            if let portrait = characterPortrait {
                dialogueBox.addChild(portrait)
            }
            
            characterName.position.x = -dialogueBox.size.width/2 + 110
            dialogueText.position.x = -dialogueBox.size.width/2 + 110
        } else {
            characterPortrait?.removeFromParent()
            characterPortrait = nil
            characterName.position.x = -dialogueBox.size.width/2 + 20
            dialogueText.position.x = -dialogueBox.size.width/2 + 20
        }
        
        show(animated: true)
    }
    
    override func update(deltaTime: TimeInterval) {
        guard !isTextComplete else { return }
        
        textTimer += deltaTime
        
        if textTimer >= textSpeed {
            textTimer = 0
            
            if displayedText.count < currentText.count {
                let nextIndex = currentText.index(currentText.startIndex, offsetBy: displayedText.count)
                displayedText.append(currentText[nextIndex])
                dialogueText.text = displayedText
                
                AudioManager.shared.playSFX("text_blip")
            } else {
                isTextComplete = true
                continueIndicator.isHidden = false
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if dialogue box was tapped
        if dialogueBox.contains(location) {
            if !isTextComplete {
                // Show all text immediately
                displayedText = currentText
                dialogueText.text = displayedText
                isTextComplete = true
                continueIndicator.isHidden = false
            } else {
                // Hide dialogue
                hudManager?.hide(.dialogue)
            }
        }
    }
    
    func nextDialogue(text: String) {
        currentText = text
        displayedText = ""
        dialogueText.text = ""
        textTimer = 0
        isTextComplete = false
        continueIndicator.isHidden = true
    }
}