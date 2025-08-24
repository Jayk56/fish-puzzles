# Sprite and Animation Consistency Guide (Simulator vs Device)

This guide documents a repeatable pipeline to normalize images and set up SpriteKit animations so they render and behave consistently on both the Simulator and physical devices.

It covers source art requirements, atlas generation, texture loading, animation setup, scale modes, and common pitfalls that cause visual or timing differences.

---

## Goals
- Same sprite orientation, crispness, and colors on simulator and device.
- No frame bleeding between atlas frames; no blurry or shifted pixels.
- Predictable animation timing regardless of device refresh rate.
- Minimal stutter by preloading textures/atlases.

---

## Quick Checklist
- Images are sRGB PNGs with straight alpha and no EXIF orientation.
- Provide `@2x`/`@3x` variants or use high‑res sources scaled down consistently.
- Atlas frames include 2–4 px transparent padding (or use packer extrude ≥2).
- All runtime textures are created through `AssetManager` (sets filtering).
- Use `SKTextureAtlas.preload`/`SKTexture.preload` before first use.
- Use time‑based `SKAction.animate` (seconds), not frame counts.
- Scene `scaleMode` and reference size are consistent across scenes.
- Avoid flip hacks like `yScale = -1`; fix orientation in the loader.
- Snap to pixel grid for tiny/1px details if needed.

Important: Do not place a single full grid sprite sheet PNG inside a `.spriteatlas` and then slice it at runtime using `SKTexture(rect:in:)`. On physical devices, atlas repacking/optimizations can cause frame index mismatches (e.g., “cycles through all frames”), while Simulator appears correct. Instead, slice to per‑frame images in the atlas (recommended), or keep the grid PNG outside the atlas and slice it there.

---

## 1) Normalize Source Images

- Format: PNG, 8‑bit/channel, straight alpha.
- Color space: sRGB IEC61966‑2.1.
  - In Asset Catalog, set each image’s Color Space to sRGB.
  - Avoid Display P3 for consistency; wide‑gamut iPhones can render more saturated colors than Simulator if P3 is used by accident.
  - Batch convert on macOS if needed:
    
    ```bash
    # Assign sRGB profile (non‑destructive)
    sips -m "/System/Library/ColorSync/Profiles/sRGB Profile.icc" path/to/*.png
    ```

- Orientation metadata: strip EXIF orientation from PNGs to avoid vertical flips on device.
  
  ```bash
  exiftool -Orientation= -n -overwrite_original path/to/*.png
  ```

- Scale factors: Prefer including `1x`, `2x`, and `3x` in `.xcassets`. If you only have one raster, supply at least a high‑res variant sized for `3x`, then downscale for others (or let the catalog scale). The Simulator often runs at 1–2x; physical devices most frequently at 2x/3x.

- Pixel padding: Add 2–4 transparent pixels around frames if you are not using an atlas packer with edge‑extrusion. This prevents bleeding when rotating/scaling.

---

## 2) Atlas Generation

You have two options. For consistency across device and Simulator, prefer the per‑frame approach:

- Xcode Sprite Atlases (`.spriteatlas` in Assets.xcassets) — per‑frame images (RECOMMENDED)
  - Simple and integrated. Xcode packs per‑frame images at build time.
  - Stable on device: avoids grid‑slicing issues caused by atlas repacking.
  - Use sequential names: `fish_01.png`, `fish_02.png`, … and sort.

- External packer (e.g., TexturePacker)
  - Set: `extrude >= 2`, `padding >= 2`, POT sheet, max size 2048.
  - Export SpriteKit format or emit `.atlas/.atlasc` pairs.

A skeleton script exists at `Scripts/generate_atlases.py`. For Xcode’s built‑in flow it creates a `.spriteatlas` folder and instructs where to copy images. For a third‑party packer, wire up the commented `TexturePacker` call and set padding/extrude there.

To regenerate atlases from `Assets/`:

```bash
make atlases
```

Recommended atlas structure in the asset catalog (per‑frame):

```
Assets.xcassets/
  FishCharacter.spriteatlas/
    fish_01.imageset/
    fish_02.imageset/
    ...
```

---

## 3) Texture Loading (normalize filtering + orientation)

Centralize all texture creation through `AssetManager` so filtering and caching are consistent.

- Existing helper: `fish-puzzles/Utilities/Helpers/AssetManager.swift`
  - `texture(named:)` caches `SKTexture(imageNamed:)`.
  - `loadTexturesFromSpriteSheet(named:rows:columns:)` slices a grid and sets `filteringMode = .nearest` and flips Y when building `rect`.

Guidelines:
- For pixel art or crisp UI edges: use `.nearest` filtering and disable node antialiasing.
- For painted art with scaling: use `.linear` filtering and consider enabling mipmaps.

Example normalization when creating nodes:

```swift
let tex = AssetManager.shared.texture(named: "button_bg")
tex.filteringMode = .nearest
let node = SKSpriteNode(texture: tex)
node.isAntialiased = false
```

If you slice grid sheets yourself, inset the sampling rect slightly to avoid bleeding at high zoom on some GPUs:

```swift
let epsilon: CGFloat = 0.0005
let rect = CGRect(x: x + epsilon, y: y + epsilon,
                  width: frameW - 2*epsilon, height: frameH - 2*epsilon)
let frame = SKTexture(rect: rect, in: spriteSheet)
frame.filteringMode = .nearest
```

Avoid runtime flip hacks like `sprite.yScale = -1`. Fix orientation in one place. If using per‑frame atlas, no grid Y‑flip is needed; if you must slice a grid PNG, only do so when the PNG is kept outside the `.spriteatlas`.

---

## 4) Using SKTextureAtlas (per‑frame approach)

If you store frames as separate images in a `.spriteatlas`, load with `SKTextureAtlas` and name ordering that sorts lexically:

```swift
let atlas = SKTextureAtlas(named: "FishCharacter")
let names = atlas.textureNames
    .filter { $0.hasPrefix("fish_") }
    .sorted() // fish_01, fish_02, ...
let frames = names.map { atlas.textureNamed($0) }
frames.forEach { $0.filteringMode = .nearest }
```

Preload to avoid hitches when an animation plays for the first time:

```swift
SKTextureAtlas.preloadTextureAtlases([atlas]) {
    // Safe to use atlas textures now
}
```

---

## 5) Animation Setup (time‑based and repeatable)

Use time‑based `SKAction.animate` and descriptive state machines. See `Core/ECS/CharacterAnimationComponent.swift` for a concrete example.

Patterns:

```swift
// Looping
let swim = SKAction.repeatForever(SKAction.animate(with: swimFrames, timePerFrame: 0.15))

// One‑shot that returns to idle
let success = SKAction.sequence([
  SKAction.animate(with: [poseFrame], timePerFrame: 1.0),
  SKAction.run { self.play(.idle) }
])

sprite.run(swim, withKey: "anim")
```

Notes:
- Prefer `timePerFrame` in seconds; do not assume a fixed FPS.
- Keep `resize` and `restore` defaults unless you need sprite size changes per frame.
- If you flip side‑to‑side, change `xScale` sign only. Keep `yScale` positive.

---

## 5a) Convert a grid sheet to a per‑frame atlas (script)

If you currently have a single grid PNG, you can convert it into an Xcode `.spriteatlas` with one frame per `.imageset` using the included script (uses macOS `sips`, no extra deps):

```bash
make slice-spritesheet \
  FILE=fish-puzzles/Assets.xcassets/FishCharacter.spriteatlas/sprite-sheet-blue-fish.imageset/sprite-sheet-blue-fish.png \
  ROWS=3 COLS=3 ATLAS=FishCharacter BASENAME=fish ORIGIN=top-left
```

This creates `fish_01.imageset`, `fish_02.imageset`, … inside `FishCharacter.spriteatlas`. Remove the original grid imageset (if any), then load frames via:

```swift
let atlas = SKTextureAtlas(named: "FishCharacter")
let frames = atlas.textureNames.sorted().map { atlas.textureNamed($0) }
```

Tip: Remove or ignore the original grid imageset to avoid duplicate assets.

---

## 6) Scale Modes, Reference Size, and Safe Areas

To keep layout predictable across devices:
- Use a consistent reference scene size derived from the view’s bounds and set `scaleMode` explicitly in each scene (e.g., `.aspectFill`). See `Scenes/Base/SceneManager.swift` and `Scenes/Location1/Location1Scene.swift`.
- Position gameplay content using safe‑area helpers rather than raw points. See `UI/SafeAreaManager.swift` and `BaseGameScene.safePosition(...)`.

If tiny elements look soft, snap positions to device pixels:

```swift
func snapToPixel(_ p: CGPoint, scale: CGFloat = UIScreen.main.scale) -> CGPoint {
  CGPoint(x: (p.x * scale).rounded() / scale,
          y: (p.y * scale).rounded() / scale)
}
```

Apply to `node.position` for hairline details.

---

## 7) Filtering, Mipmaps, and Antialiasing

Pick one per asset category and be consistent:

- Pixel art / crisp UI
  - `texture.filteringMode = .nearest`
  - `sprite.isAntialiased = false`
  - `texture.usesMipmaps = false`

- Painted art / downscaled images
  - `texture.filteringMode = .linear`
  - Consider `texture.usesMipmaps = true` for smoother minification.

Mixing modes is fine as long as each asset type is intentional and consistent.

---

## 8) Performance and Preloading

- Preload atlases and loose textures during scene load to avoid first‑use stalls:

  ```swift
  let names = ["sprite-sheet-blue-fish", "button_bg", "spark"]
  AssetManager.shared.preloadTextures(names) {
    // Start scene interactions
  }
  ```

- The engine already standardizes refresh rate: `SceneManager` sets `SKView.preferredFramesPerSecond = 60`.
- Keep `view.ignoresSiblingOrder = true` for SpriteKit batching (also set by `SceneManager`).

---

## 9) Troubleshooting Differences

- Flipped or upside‑down frames
  - Ensure grid slicing flips Y once in the loader; do not also flip sprites with `yScale = -1`.

- Texture bleeding between animation frames
  - Ensure 2–4 px transparent padding or use packer `extrude >= 2`.
  - Inset `SKTexture(rect:in:)` by a tiny epsilon (see above).

- Blurry sprites on device but not Simulator
  - Confirm `@2x/@3x` assets exist or that you intentionally use `.nearest` upscaling.
  - Set `sprite.isAntialiased = false` for crisp edges.

- Color shifts (more saturated on device)
  - Make sure all PNGs are sRGB and asset entries are set to sRGB.

- Animations run faster/slower on some devices
  - Use `timePerFrame` in seconds and avoid frame‑count logic tied to refresh rate.
  - For manual updates, always compute `deltaTime` in `update(_:)` (already used in `BaseGameScene`).

- First animation hitch on device only
  - Preload textures/atlases during scene setup before playing the animation.

- Device cycles all frames but Simulator plays correct sequence
  - Likely caused by slicing a full grid PNG inside a `.spriteatlas`. On device, atlas repacking/optimizations can reorder or rotate content.
  - Fix by slicing to per‑frame images in the atlas (preferred). Alternatively, keep the grid PNG outside the atlas and slice it there.

---

## 10) Project‑Specific Notes

- `AssetManager.loadTexturesFromSpriteSheet` already:
  - Flips Y when slicing grid‑based sheets.
  - Sets `filteringMode = .nearest` on frames.

  Prefer leaving `yScale` as `1.0` on sprites created from these frames. If any scene currently sets `yScale = -1` to correct orientation, remove that line and rely on the loader’s orientation.

- Several systems create textures directly via `SKTexture(imageNamed:)` (e.g., particles and ad‑hoc animations in `InteractionSystem`). For consistency, route these through `AssetManager.texture(named:)` and set filtering (`nearest` for pixel‑style assets, `linear` for painted assets).

- Atlas content: The project includes `FishCharacter.spriteatlas` with a single 1x sheet. For best results on physical devices, add 2x/3x variants to the image set or ship a higher‑resolution sheet and let the catalog scale down.

---

## Reference Snippets

- Grid‑based sprite sheet slicing with Y‑flip and epsilon inset:

```swift
func frames(fromSheet name: String, rows: Int, columns: Int) -> [SKTexture] {
  let sheet = SKTexture(imageNamed: name)
  let w = 1.0 / CGFloat(columns)
  let h = 1.0 / CGFloat(rows)
  let eps: CGFloat = 0.0005
  var out: [SKTexture] = []
  for r in 0..<rows {
    for c in 0..<columns {
      let x = CGFloat(c) * w
      let y = CGFloat(rows - 1 - r) * h // SpriteKit Y origin
      let rect = CGRect(x: x + eps, y: y + eps, width: w - 2*eps, height: h - 2*eps)
      let t = SKTexture(rect: rect, in: sheet)
      t.filteringMode = .nearest
      out.append(t)
    }
  }
  return out
}
```

- State‑driven animation with preload:

```swift
let atlas = SKTextureAtlas(named: "FishCharacter")
SKTextureAtlas.preloadTextureAtlases([atlas]) {
  let frames = atlas.textureNames.sorted().map { atlas.textureNamed($0) }
  frames.forEach { $0.filteringMode = .nearest }
  let swim = SKAction.repeatForever(SKAction.animate(with: frames, timePerFrame: 0.15))
  sprite.run(swim, withKey: "anim")
}
```

- Pixel snapping helper:

```swift
func snapToPixel(_ p: CGPoint, scale: CGFloat = UIScreen.main.scale) -> CGPoint {
  CGPoint(x: (p.x * scale).rounded() / scale,
          y: (p.y * scale).rounded() / scale)
}
```

---

## Adoption Plan

1) Update art where needed (sRGB, padding, 2x/3x variants).
2) Decide on atlas strategy and standardize naming.
3) Route all texture creation through `AssetManager` and set filtering.
4) Remove any `yScale = -1` flips; fix orientation in the loader.
5) Preload textures/atlases in scene setup before first use.
6) Validate on device and simulator using a known animation sequence and a 1‑pixel test sprite snapped to the grid.

If you want, I can follow up with a small PR that refactors direct `SKTexture(imageNamed:)` usages to go through `AssetManager` and removes per‑scene flip hacks.
