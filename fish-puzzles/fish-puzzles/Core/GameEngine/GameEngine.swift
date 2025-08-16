//
//  GameEngine.swift
//  fish-puzzles
//
//  Core game engine that manages the game lifecycle
//

import Foundation
import SpriteKit

final class GameEngine {
    static let shared = GameEngine()
    
    private(set) var gameState: GameState
    private var sceneManager: SceneManager?
    
    private init() {
        self.gameState = GameState()
    }
    
    func start(with view: SKView) {
        sceneManager = SceneManager(view: view)
        sceneManager?.loadMainMenu()
    }
    
    func pause() {
        sceneManager?.currentScene?.isPaused = true
        gameState.isPaused = true
    }
    
    func resume() {
        sceneManager?.currentScene?.isPaused = false
        gameState.isPaused = false
    }
    
    func handleMemoryWarning() {
        AssetManager.shared.clearCache()
    }
    
    // MARK: - State Modification Methods
    
    func addItemToInventory(_ item: Item) {
        gameState.inventory.add(item)
        gameState.itemsCollected.insert(item.id)
        SaveManager.shared.save(gameState)
    }
    
    func removeItemFromInventory(_ itemID: String) {
        gameState.inventory.remove(itemID)
        SaveManager.shared.save(gameState)
    }
    
    func markPuzzleSolved(_ puzzleID: String) {
        gameState.puzzlesSolved.insert(puzzleID)
        SaveManager.shared.save(gameState)
    }
    
    func markSceneCompleted(_ sceneID: String) {
        gameState.completedScenes.insert(sceneID)
        SaveManager.shared.save(gameState)
    }
    
    func updateCurrentScene(_ sceneID: String) {
        gameState.currentSceneID = sceneID
        SaveManager.shared.save(gameState)
    }
    
    func updatePlayTime(_ additionalTime: TimeInterval) {
        gameState.playTime += additionalTime
    }
    
    func incrementHintsUsed() {
        gameState.hintsUsed += 1
    }
    
    func updateVolume(music: Float? = nil, sfx: Float? = nil, voice: Float? = nil) {
        if let music = music {
            gameState.musicVolume = music
        }
        if let sfx = sfx {
            gameState.sfxVolume = sfx
        }
        if let voice = voice {
            gameState.voiceVolume = voice
        }
        SaveManager.shared.save(gameState)
    }
}
