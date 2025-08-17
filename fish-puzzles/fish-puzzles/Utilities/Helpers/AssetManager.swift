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
    
    func loadTexturesFromSpriteSheet(named: String, rows: Int, columns: Int) -> [SKTexture] {
        let spriteSheet = SKTexture(imageNamed: named)
        var textures: [SKTexture] = []
        
        // Check if texture loaded successfully
        if spriteSheet.size() == CGSize.zero {
            print("⚠️ Failed to load sprite sheet texture: \(named)")
            print("   Try using just the image name without path")
            return textures
        }
        
        print("✅ Loaded sprite sheet: \(named), size: \(spriteSheet.size())")
        
        let frameWidth = 1.0 / CGFloat(columns)
        let frameHeight = 1.0 / CGFloat(rows)
        
        for row in 0..<rows {
            for col in 0..<columns {
                let x = CGFloat(col) * frameWidth
                let y = CGFloat(rows - 1 - row) * frameHeight // Flip Y coordinate for SpriteKit
                
                let rect = CGRect(x: x, y: y, width: frameWidth, height: frameHeight)
                let texture = SKTexture(rect: rect, in: spriteSheet)
                texture.filteringMode = .nearest // Keep pixel art crisp
                textures.append(texture)
            }
        }
        
        print("   Created \(textures.count) texture frames")
        return textures
    }
    
    func clearCache() {
        textureCache.removeAll()
    }
}
