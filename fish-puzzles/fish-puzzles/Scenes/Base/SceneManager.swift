//
//  SceneManager.swift
//  fish-puzzles
//
//  Manages scene transitions and lifecycle
//

import Foundation
import SpriteKit

final class SceneManager {
    private weak var view: SKView?
    private(set) var currentScene: BaseGameScene?
    
    init(view: SKView) {
        self.view = view
        setupView()
    }
    
    private func setupView() {
        guard let view = view else { return }
        
        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        view.showsPhysics = false
        #endif
        
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
    }
    
    func loadMainMenu() {
        transition(to: MainMenuScene(size: view?.bounds.size ?? CGSize(width: 1024, height: 768)))
    }
    
    func loadScene(_ sceneID: String) {
        // Scene factory would go here
        switch sceneID {
        case "Location1":
            transition(to: Location1Scene(size: view?.bounds.size ?? CGSize(width: 1024, height: 768)))
        case "Location2":
            transition(to: Location2Scene(size: view?.bounds.size ?? CGSize(width: 1024, height: 768)))
        default:
            loadMainMenu()
        }
    }
    
    private func transition(to scene: BaseGameScene, transition: SKTransition = .fade(withDuration: 1.0)) {
        currentScene = scene
        view?.presentScene(scene, transition: transition)
    }
}
