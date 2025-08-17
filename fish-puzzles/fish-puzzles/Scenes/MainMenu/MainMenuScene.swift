//
//  MainMenuScene.swift
//  fish-puzzles
//
//  Main menu scene
//

import SpriteKit

class MainMenuScene: BaseGameScene {
    override func setupScene() {
        super.setupScene()
        
        // Set scene scaling mode for landscape
        scaleMode = .aspectFill
        
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
        addChild(playButton)
        
        let playLabel = SKLabelNode(text: "Play")
        playLabel.fontSize = buttonHeight * 0.5
        playLabel.fontName = "Helvetica"
        playLabel.verticalAlignmentMode = .center
        playButton.addChild(playLabel)
        
        // Register hotspot for play button
        let playHotspot = Hotspot(
            id: "play",
            frame: playButton.frame,
            action: { [weak self] in
                self?.startGame()
            }
        )
        interactionSystem.registerHotspot(playHotspot)
        
        // Play menu music
        AudioManager.shared.playMusic("menu_theme")
    }
    
    private func startGame() {
        guard let view = view else { 
            print("⚠️ No view available to transition scene")
            return 
        }
        SceneManager(view: view).loadScene("Location1")
    }
}
