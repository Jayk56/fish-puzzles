//
//  BaseMenuScene.swift
//  fish-puzzles
//
//  Base class for menu scenes with simple UI interaction
//

import SpriteKit

class BaseMenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Make the scene an accessibility container for UI testing
        isAccessibilityElement = false
        
        // Setup the menu
        setupMenu()
    }
    
    // Override in subclasses to setup menu elements
    func setupMenu() {
        // Override in subclasses
    }
    
    // MARK: - Simple Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        // Handle touch by checking node names
        handleNodeTap(node)
    }
    
    // Handle tap on a specific node
    func handleNodeTap(_ node: SKNode) {
        // Check the node or its parent for button names
        if let nodeName = node.name {
            handleButtonTap(nodeName)
        } else if let parentName = node.parent?.name {
            handleButtonTap(parentName)
        }
    }
    
    // Override in subclasses to handle specific button taps
    func handleButtonTap(_ buttonName: String) {
        // Default implementation plays a tap sound
        AudioManager.shared.playSFX("button_tap")
        
        // Subclasses should override and call super, then handle specific buttons
    }
    
    // MARK: - Scene Transition Helpers
    func transitionToScene(named sceneName: String) {
        guard let view = view else { 
            print("⚠️ No view available to transition scene")
            return 
        }
        SceneManager(view: view).loadScene(sceneName)
    }
    
    func transitionToMainMenu() {
        guard let view = view else { 
            print("⚠️ No view available to transition scene")
            return 
        }
        SceneManager(view: view).loadMainMenu()
    }
}