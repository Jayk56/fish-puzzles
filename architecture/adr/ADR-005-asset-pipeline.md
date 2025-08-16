# ADR-005: Asset Pipeline and Memory Management

## Status
Accepted

## Context
The game requires efficient handling of:
- Hand-drawn 2D artwork (backgrounds, characters, items)
- Voice-over audio files (potentially hundreds)
- Music tracks and sound effects
- Multiple texture resolutions for different devices
- Localization assets for future languages

With constraints:
- <500MB download size
- <200MB runtime memory
- 60 FPS performance
- Fast scene transitions (<1 second)

## Decision
Implement a sophisticated asset pipeline with:
- **Texture atlasing**: Scene-based atlases with automatic packing
- **On-demand loading**: Load only current + next scene
- **Compression**: ASTC for textures, AAC for audio
- **App thinning**: Device-specific resources
- **Intelligent caching**: LRU cache with memory pressure handling

## Architecture
```swift
class AssetPipeline {
    // Build-time
    struct AtlasConfiguration {
        let maxSize = CGSize(width: 2048, height: 2048)
        let padding = 2
        let algorithm = PackingAlgorithm.maxRects
    }
    
    // Runtime
    class AssetLoader {
        private let cache = NSCache<NSString, SKTexture>()
        private let preloadQueue = DispatchQueue(label: "preload", qos: .background)
        
        func loadScene(_ sceneID: String) async -> SceneAssets
        func preloadNextScene(_ sceneID: String)
        func unloadDistantScenes()
    }
}
```

## Asset Organization
```
Assets/
├── Atlases/
│   ├── Scene01.atlas     (background + scene-specific)
│   ├── Scene02.atlas
│   ├── Characters.atlas  (shared across scenes)
│   └── UI.atlas          (persistent)
├── Audio/
│   ├── VO/
│   │   ├── en/          (English voice-overs)
│   │   └── [future languages]/
│   ├── Music/
│   └── SFX/
└── Data/
    ├── Scenes/
    └── Localization/
```

## Memory Budget Allocation
| Category | Budget | Notes |
|----------|--------|-------|
| Current Scene | 50MB | Backgrounds, active sprites |
| Characters | 30MB | Shared character atlas |
| UI | 20MB | Persistent UI elements |
| Audio Buffer | 30MB | Current VO + music |
| Next Scene | 40MB | Preloaded assets |
| Cache | 30MB | Recently used textures |
| **Total** | **200MB** | With overhead |

## Consequences

### Positive
- **Optimal memory usage**: Never exceed 200MB budget
- **Fast loading**: Preloading enables instant transitions
- **Device-optimized**: App thinning reduces download
- **Retina quality**: High-res assets for all devices
- **Future-proof**: Ready for additional content

### Negative
- **Build complexity**: Atlas generation pipeline required
- **Artist constraints**: Must follow atlas guidelines
- **Loading logic**: Complex preload/unload management
- **Testing overhead**: Multiple device configurations

## Implementation Details

### Texture Atlas Pipeline
```bash
# Build script
texture-packer \
  --format spritekit \
  --max-size 2048 \
  --size-constraints POT \
  --algorithm MaxRects \
  --pack-mode Best \
  --texture-format png \
  --opt RGBA8888 \
  --premultiply-alpha
```

### Memory Pressure Handling
```swift
class MemoryManager {
    override func didReceiveMemoryWarning() {
        // Level 1: Clear distant cache
        assetCache.removeObjects(olderThan: 60)
        
        // Level 2: Reduce quality
        textureLoader.reduceQuality()
        
        // Level 3: Emergency unload
        sceneManager.unloadInactiveScenes()
    }
}
```

### App Thinning Configuration
```xml
<!-- Asset Catalogs -->
<device-capabilities>
  <graphics>metal</graphics>
  <memory>2GB,3GB,4GB,6GB</memory>
  <screen>retina,retina-hd,retina-xdr</screen>
</device-capabilities>
```

## Alternatives Considered

1. **Individual sprites**: Simple but inefficient
   - Rejected: Too many draw calls, poor performance

2. **Single mega-atlas**: One atlas for everything
   - Rejected: Exceeds memory budget, slow loading

3. **Runtime packing**: Dynamic atlas generation
   - Rejected: CPU overhead, unpredictable performance

4. **Asset bundles**: Downloadable content packs
   - Rejected: Complexity for MVP, internet required

## Performance Metrics
- Scene load time: <1 second
- Memory peak: <200MB
- Draw calls: <50 per frame
- Texture switches: <10 per frame
- Cache hit rate: >80%

## References
- [Apple - App Thinning](https://developer.apple.com/documentation/xcode/reducing-your-app-s-size)
- [Texture Packer](https://www.codeandweb.com/texturepacker)
- [ASTC Texture Compression](https://developer.apple.com/documentation/metal/textures/choosing_a_pixel_format_for_texture_compression)