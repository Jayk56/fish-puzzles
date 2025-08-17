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
        let sceneSize = getSceneSize()
        let scene = MainMenuScene(size: sceneSize)
        transition(to: scene)
    }
    
    func loadScene(_ sceneID: String) {
        let sceneSize = getSceneSize()
        
        // Scene factory would go here
        switch sceneID {
        case "Location1":
            transition(to: Location1Scene(size: sceneSize))
        case "Location2":
            transition(to: Location2Scene(size: sceneSize))
        default:
            loadMainMenu()
        }
    }
    
    private func getSceneSize() -> CGSize {
        guard let view = view else {
            // Default landscape size for iPad
            return CGSize(width: 1024, height: 768)
        }
        
        // Ensure we're using landscape dimensions
        let bounds = view.bounds
        let width = max(bounds.width, bounds.height)
        let height = min(bounds.width, bounds.height)
        
        return CGSize(width: width, height: height)
    }
    
    private func transition(to scene: BaseGameScene, transition: SKTransition = .fade(withDuration: 1.0)) {
        currentScene = scene
        view?.presentScene(scene, transition: transition)
    }
}
