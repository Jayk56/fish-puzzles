//
//  GameState.swift
//  fish-puzzles
//
//  Central game state management
//

import Foundation

struct GameState: Codable {
    var currentSceneID: String = "MainMenu"
    var inventory: Inventory = Inventory()
    var completedScenes: Set<String> = []
    var playTime: TimeInterval = 0
    var isPaused: Bool = false
    
    // Player progress
    var puzzlesSolved: Set<String> = []
    var itemsCollected: Set<String> = []
    var hintsUsed: Int = 0
    
    // Settings
    var musicVolume: Float = 1.0
    var sfxVolume: Float = 1.0
    var voiceVolume: Float = 1.0
    var subtitlesEnabled: Bool = true
}

struct Inventory: Codable {
    private var items: [String: Item] = [:]
    
    mutating func add(_ item: Item) {
        items[item.id] = item
    }
    
    mutating func remove(_ itemID: String) {
        items.removeValue(forKey: itemID)
    }
    
    func contains(_ itemID: String) -> Bool {
        items[itemID] != nil
    }
    
    var allItems: [Item] {
        Array(items.values)
    }
}

struct Item: Codable {
    let id: String
    let name: String
    let imageName: String
    var quantity: Int = 1
}
