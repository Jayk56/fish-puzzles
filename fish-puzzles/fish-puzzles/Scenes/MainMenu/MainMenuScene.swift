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
        
        // Background
        let background = SKSpriteNode(color: .systemBlue, size: size)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(background)
        
        // Title
        let title = SKLabelNode(text: "Fish Puzzles")
        title.fontSize = 48
        title.fontName = "Helvetica-Bold"
        title.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        addChild(title)
        
        // Play button
        let playButton = SKSpriteNode(color: .systemGreen, size: CGSize(width: 200, height: 60))
        playButton.position = CGPoint(x: size.width/2, y: size.height * 0.4)
        playButton.name = "playButton"
        addChild(playButton)
        
        let playLabel = SKLabelNode(text: "Play")
        playLabel.fontSize = 32
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
