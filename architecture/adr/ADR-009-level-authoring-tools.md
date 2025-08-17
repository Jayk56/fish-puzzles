# ADR-009: Level Authoring Tools Architecture

## Status
Accepted

## Context
Level designers need tools to:
- Create and customize game scenes without programming
- Place entities and configure interactions
- Design puzzles using reusable templates
- Test scenes quickly during development
- Share and version control level data

We need an authoring system that balances power with ease of use for non-technical team members.

## Decision
Build a two-part level authoring system:
1. **Scene Editor**: Visual tool for scene composition (macOS app)
2. **Scene Definitions**: JSON-based level data format
3. **Puzzle Templates**: Reusable interaction patterns library
4. **Live Preview**: Real-time testing in game engine

## Architecture

### Scene Editor Application (macOS)
```swift
// SceneEditor.app structure
class SceneEditor: NSDocument {
    // Visual canvas for entity placement
    // Property inspector for component editing  
    // Asset browser for sprites/audio
    // Puzzle template library
    // Export to JSON format
}

// Core editor components
struct EditorCanvas {
    func placeEntity(at point: CGPoint, type: EntityTemplate)
    func selectEntity(_ entity: EditorEntity)
    func moveEntity(_ entity: EditorEntity, to point: CGPoint)
    func deleteEntity(_ entity: EditorEntity)
}

struct PropertyInspector {
    func showProperties(for entity: EditorEntity)
    func updateComponent(_ component: ComponentData)
    func addComponent(type: ComponentType, to entity: EditorEntity)
}

struct AssetBrowser {
    func browseSprites() -> [SpriteAsset]
    func browseAudio() -> [AudioAsset]
    func browsePuzzleTemplates() -> [PuzzleTemplate]
}
```

### Scene Definition Format (JSON)
```json
{
  "sceneId": "location1_main",
  "metadata": {
    "name": "Coral Reef Garden",
    "author": "level_designer_1",
    "version": "1.0.0",
    "createdAt": "2024-01-15T10:00:00Z"
  },
  "settings": {
    "backgroundImage": "coral_reef_bg.png",
    "backgroundMusic": "underwater_ambience.mp3",
    "lightingPreset": "bright_day"
  },
  "entities": [
    {
      "id": "chest_001",
      "type": "treasure_chest",
      "position": {"x": 450, "y": 320},
      "components": {
        "sprite": {
          "texture": "chest_closed.png",
          "size": {"width": 80, "height": 60}
        },
        "interaction": {
          "approachPoint": {"x": 450, "y": 280},
          "requiredItem": "golden_key",
          "onInteract": {
            "action": "openContainer",
            "reward": ["pearl", "map_piece_1"]
          }
        },
        "navigation": {
          "blockedArea": {"x": 410, "y": 310, "width": 80, "height": 50},
          "depthLayer": 2
        }
      }
    }
  ],
  "puzzles": [
    {
      "id": "door_puzzle",
      "template": "sequence_lock",
      "config": {
        "sequence": ["red", "blue", "green"],
        "hints": ["Look at the painting", "Colors of the rainbow"],
        "solution": "unlocks_secret_room"
      }
    }
  ],
  "triggers": [
    {
      "id": "scene_enter",
      "event": "onSceneLoad",
      "action": "playDialogue",
      "params": {"character": "freddi", "line": "welcome_coral_reef"}
    }
  ]
}
```

### Puzzle Template Library
```swift
// Reusable puzzle patterns
enum PuzzleTemplate {
    case itemCombination      // Combine A + B = C
    case sequenceLock         // Enter correct sequence
    case patternMatch         // Match visual pattern
    case findHiddenObject     // Click on hidden item
    case characterDialogue    // Choose correct response
    case timedChallenge       // Complete before timer
    case memoryGame           // Remember and repeat
    case sortingPuzzle        // Arrange items correctly
}

// Template configuration
struct PuzzleConfiguration {
    let template: PuzzleTemplate
    let difficulty: Difficulty
    let hints: [String]
    let solution: PuzzleSolution
    let rewards: [String]
}
```

### Live Preview System
```swift
// In-game debug mode for testing
class SceneDebugMode {
    func loadSceneFromFile(_ path: String)
    func reloadCurrentScene()
    func showEntityBounds(_ show: Bool)
    func showNavigationMesh(_ show: Bool)
    func showInteractionZones(_ show: Bool)
    func skipToCheckpoint(_ id: String)
    func giveItem(_ itemId: String)
    func solvePuzzle(_ puzzleId: String)
}

// Hot reload support
class HotReloadManager {
    func watchSceneFile(_ path: String)
    func onFileChanged(_ handler: () -> Void)
    func reloadScene(preserveState: Bool)
}
```

## Workflow Integration

### Development Pipeline
```
1. Designer creates scene in SceneEditor.app
2. Exports to JSON in project's Scenes/ folder
3. Game loads JSON at runtime
4. Designer tests in debug mode
5. Iterates based on playtesting
6. Commits JSON to version control
```

### CI/CD Validation
```yaml
# Automated scene validation
scene-validation:
  - JSON schema compliance
  - Asset reference checking
  - Puzzle logic verification
  - Performance budget check
  - Accessibility audit
```

## Consequences

### Positive
- **Rapid iteration**: Designers can test changes immediately
- **No compilation**: JSON scenes load without rebuilding
- **Version control**: Text-based format works with Git
- **Reusability**: Puzzle templates speed up level creation
- **Collaboration**: Designers and developers work in parallel
- **Debugging**: Visual tools help identify issues quickly

### Negative
- **Tool development**: Significant upfront investment
- **Training required**: Team needs to learn new tools
- **Maintenance burden**: Editor needs updates with game
- **Platform limitation**: Editor only runs on macOS
- **Performance**: JSON parsing overhead at runtime

### Risks
- **Tool complexity**: Editor becomes too complex for designers
- **Format evolution**: Breaking changes in JSON schema
- **Asset dependencies**: Missing or moved assets break scenes

## Alternatives Considered

1. **Unity/Godot style**: Full game engine editor
   - Rejected: Overkill for 2D point-and-click

2. **Code-only**: Scenes defined in Swift code
   - Rejected: Not accessible to non-programmers

3. **Third-party tools**: Tiled, Overlap2D
   - Rejected: Not tailored to our specific needs

4. **Web-based editor**: Browser-based tool
   - Rejected: More complex, requires backend

## Implementation Phases

### Phase 1: Core Format (MVP)
- JSON schema definition
- Basic scene loader
- Manual JSON editing

### Phase 2: Debug Tools
- In-game debug mode
- Hot reload support
- Visual debugging overlays

### Phase 3: Visual Editor
- macOS SceneEditor app
- Drag-and-drop interface
- Property inspector

### Phase 4: Advanced Features
- Puzzle template library
- Multi-scene management
- Collaboration features

## References
- [Level Design Patterns](https://www.gamedeveloper.com/design/level-design-patterns)
- [JSON Schema](https://json-schema.org/)
- [Apple SceneKit Editor](https://developer.apple.com/documentation/scenekit/scnscene)