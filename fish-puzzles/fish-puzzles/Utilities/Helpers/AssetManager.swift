//
//  AssetManager.swift
//  fish-puzzles
//
//  Manages texture loading and caching
//

import SpriteKit

final class AssetManager {
    static let shared = AssetManager()
    
    private var textureCache: [String: SKTexture] = [:]
    
    private init() {}
    
    func texture(named name: String) -> SKTexture {
        if let cached = textureCache[name] {
            return cached
        }
        
        let texture = SKTexture(imageNamed: name)
        textureCache[name] = texture
        return texture
    }
    
    func preloadTextures(_ names: [String], completion: @escaping () -> Void) {
        let textures = names.map { SKTexture(imageNamed: $0) }
        SKTexture.preload(textures) {
            names.enumerated().forEach { index, name in
                self.textureCache[name] = textures[index]
            }
            completion()
        }
    }
    
    func clearCache() {
        textureCache.removeAll()
    }
}
