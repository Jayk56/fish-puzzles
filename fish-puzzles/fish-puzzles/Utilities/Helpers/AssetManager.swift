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
    // Some externally prepared sheets may be vertically inverted relative to
    // SpriteKit's expectations. Centralize one-off flips here so we can remove
    // them later when assets are re-exported.
    private let verticallyFlippedSpriteSheets: Set<String> = [
        "sprite-sheet-blue-fish"
    ]
    // Some sheets may already be authored bottom-up; skip the grid Y-flip for those.
    private let skipGridYFlipForSheets: Set<String> = [
        // Add sheet names here if device shows wrong row order
    ]
    
    private init() {}
    
    func needsVerticalFlip(forSheet name: String) -> Bool {
        return verticallyFlippedSpriteSheets.contains(name)
    }
    
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
        // Small inset to prevent GPU sampling bleeding across frame edges on device
        let eps: CGFloat = 0.0005
        
        let flipGridY = !skipGridYFlipForSheets.contains(named)
        for row in 0..<rows {
            for col in 0..<columns {
                let x = CGFloat(col) * frameWidth
                // Flip grid Y by default to treat row 0 as top row.
                // Some prepared sheets (esp. pre-packed) may already be bottom-up.
                let gridRow = flipGridY ? (rows - 1 - row) : row
                let y = CGFloat(gridRow) * frameHeight
                // Inset by a tiny epsilon on all sides to avoid sampling neighbors
                let rect = CGRect(
                    x: x + eps,
                    y: y + eps,
                    width: frameWidth - 2 * eps,
                    height: frameHeight - 2 * eps
                )
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
