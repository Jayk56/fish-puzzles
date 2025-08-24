//
//  MainMenuScene.swift
//  fish-puzzles
//
//  Main menu scene with simple UI interaction
//

import SpriteKit

class MainMenuScene: BaseMenuScene {
    
    override func setupMenu() {
        super.setupMenu()
        
        // Set scene scaling mode for landscape
        scaleMode = .aspectFill
        
        // Preload character atlas so first scene animates immediately
        let fishAtlas = SKTextureAtlas(named: "FishCharacter")
        SKTextureAtlas.preloadTextureAtlases([fishAtlas]) {
            print("✅ Preloaded FishCharacter atlas in Main Menu")
        }
        
        // Background
        let background = SKSpriteNode(color: .systemBlue, size: size)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
        
        // Title - scale based on screen width for landscape
        let title = SKLabelNode(text: "Fish Puzzles")
        let baseFontSize: CGFloat = size.width > 800 ? 72 : 56
        title.fontSize = baseFontSize
        title.fontName = "Helvetica-Bold"
        title.position = CGPoint(x: size.width/2, y: size.height * 0.65)
        title.zPosition = 1
        addChild(title)
        
        // Play button - scale proportionally to screen
        let buttonWidth = min(size.width * 0.25, 250)
        let buttonHeight = buttonWidth * 0.35
        let playButton = SKSpriteNode(color: .systemGreen, size: CGSize(width: buttonWidth, height: buttonHeight))
        playButton.position = CGPoint(x: size.width/2, y: size.height * 0.4)
        playButton.name = "playButton"
        playButton.zPosition = 1
        
        // Add accessibility support for UI testing
        playButton.isAccessibilityElement = true
        playButton.accessibilityLabel = "playButton"  // This acts as the identifier in SpriteKit
        playButton.accessibilityTraits = .button
        
        addChild(playButton)
        
        let playLabel = SKLabelNode(text: "Play")
        playLabel.fontSize = buttonHeight * 0.5
        playLabel.fontName = "Helvetica"
        playLabel.verticalAlignmentMode = .center
        playButton.addChild(playLabel)
        
        // Play menu music
        AudioManager.shared.playMusic("menu_theme")
    }
    
    override func handleButtonTap(_ buttonName: String) {
        super.handleButtonTap(buttonName)  // Plays tap sound
        
        switch buttonName {
        case "playButton":
            startGame()
        default:
            break
        }
    }
    
    private func startGame() {
        transitionToScene(named: "Location1")
    }
}
