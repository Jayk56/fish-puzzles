//
//  SaveManager.swift
//  fish-puzzles
//
//  Handles game saves with CloudKit sync
//

import Foundation
import CloudKit

final class SaveManager {
    static let shared = SaveManager()
    
    private let saveKey = "FishPuzzles.SaveGame"
    private let container = CKContainer(identifier: "iCloud.com.yourcompany.fishpuzzles")
    
    private init() {}
    
    // MARK: - Local Save
    func save(_ gameState: GameState) {
        do {
            let data = try JSONEncoder().encode(gameState)
            UserDefaults.standard.set(data, forKey: saveKey)
            
            // Also sync to CloudKit
            Task {
                await syncToCloud(gameState)
            }
        } catch {
            print("Failed to save game: \(error)")
        }
    }
    
    func load() -> GameState? {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return nil }
        
        do {
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            print("Failed to load game: \(error)")
            return nil
        }
    }
    
    // MARK: - CloudKit Sync
    private func syncToCloud(_ gameState: GameState) async {
        // CloudKit implementation would go here
        // For MVP, local saves are sufficient
    }
}
