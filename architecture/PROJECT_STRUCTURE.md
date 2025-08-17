# Project Structure & Scaffolding

## Complete Project Structure

```
FishPuzzles/
├── FishPuzzles.xcodeproj/
├── FishPuzzles.xcworkspace/
├── Modules/                      # Modular architecture
│   ├── App/
│   │   ├── Sources/
│   │   │   ├── AppDelegate.swift
│   │   │   ├── SceneDelegate.swift
│   │   │   ├── RootCoordinator.swift
│   │   │   └── DependencyContainer.swift
│   │   ├── Resources/
│   │   │   ├── Info.plist
│   │   │   ├── Assets.xcassets
│   │   │   └── LaunchScreen.storyboard
│   │   └── Tests/
│   ├── GameCore/
│   │   ├── Sources/
│   │   │   ├── GameEngine.swift
│   │   │   ├── GameState.swift
│   │   │   ├── GameLoop.swift
│   │   │   ├── ECS/
│   │   │   │   ├── Entity.swift
│   │   │   │   ├── Component.swift
│   │   │   │   └── System.swift
│   │   │   └── Protocols/
│   │   ├── Tests/
│   │   └── Resources/
│   ├── SceneManagement/
│   │   ├── Sources/
│   │   │   ├── SceneManager.swift
│   │   │   ├── SceneFactory.swift
│   │   │   ├── Scenes/
│   │   │   │   ├── BaseScene.swift
│   │   │   │   ├── MainMenuScene.swift
│   │   │   │   ├── Location1Scene.swift
│   │   │   │   └── Location2Scene.swift
│   │   │   └── Transitions/
│   │   ├── Tests/
│   │   └── Resources/
│   ├── InteractionSystem/
│   │   ├── Sources/
│   │   │   ├── InteractionManager.swift
│   │   │   ├── TouchHandler.swift
│   │   │   ├── Hotspot.swift
│   │   │   └── Components/
│   │   ├── Tests/
│   │   └── Resources/
│   ├── InventorySystem/
│   │   ├── Sources/
│   │   │   ├── InventoryManager.swift
│   │   │   ├── Item.swift
│   │   │   ├── CombinationRules.swift
│   │   │   └── UI/
│   │   ├── Tests/
│   │   └── Resources/
│   ├── AudioSystem/
│   │   ├── Sources/
│   │   │   ├── AudioManager.swift
│   │   │   ├── MusicController.swift
│   │   │   ├── VOPlayer.swift
│   │   │   └── SFXMixer.swift
│   │   ├── Tests/
│   │   └── Resources/
│   ├── SaveSystem/
│   │   ├── Sources/
│   │   │   ├── SaveManager.swift
│   │   │   ├── LocalPersistence.swift
│   │   │   ├── CloudSync.swift
│   │   │   └── Models/
│   │   ├── Tests/
│   │   └── Resources/
│   ├── AssetPipeline/
│   │   ├── Sources/
│   │   │   ├── AssetLoader.swift
│   │   │   ├── TextureCache.swift
│   │   │   └── AtlasManager.swift
│   │   ├── Tests/
│   │   └── Resources/
│   ├── Analytics/
│   │   ├── Sources/
│   │   │   ├── Analytics.swift
│   │   │   ├── EventProcessor.swift
│   │   │   └── PrivacyGuard.swift
│   │   ├── Tests/
│   │   └── Resources/
│   ├── UIComponents/
│   │   ├── Sources/
│   │   │   ├── UIManager.swift
│   │   │   ├── Screens/
│   │   │   ├── HUD/
│   │   │   └── Components/
│   │   ├── Tests/
│   │   └── Resources/
│   ├── Localization/
│   │   ├── Sources/
│   │   │   ├── LocalizationManager.swift
│   │   │   └── StringTable.swift
│   │   ├── Tests/
│   │   └── Resources/
│   └── Accessibility/
│       ├── Sources/
│       │   ├── AccessibilityManager.swift
│       │   └── VoiceOverAdapter.swift
│       ├── Tests/
│       └── Resources/
├── Assets/                       # Raw assets (not in version control)
│   ├── Art/
│   │   ├── Characters/
│   │   ├── Backgrounds/
│   │   ├── Items/
│   │   └── UI/
│   ├── Audio/
│   │   ├── Music/
│   │   ├── VO/
│   │   │   └── en/
│   │   └── SFX/
│   └── Data/
│       ├── Scenes/
│       ├── Puzzles/
│       └── Dialogue/
├── ProcessedAssets/             # Build-time generated
│   ├── Atlases/
│   ├── CompressedAudio/
│   └── Catalogs/
├── Configuration/
│   ├── Debug.xcconfig
│   ├── Staging.xcconfig
│   ├── Release.xcconfig
│   └── Settings.bundle/
├── Scripts/                     # Build and automation
│   ├── build.sh
│   ├── generate_atlases.py
│   ├── compress_audio.sh
│   ├── localization_sync.rb
│   └── ci/
│       ├── test.yml
│       ├── build.yml
│       └── deploy.yml
├── Documentation/
│   ├── architecture/
│   │   ├── ARCHITECTURE.md
│   │   ├── MODULES.md
│   │   ├── PROJECT_STRUCTURE.md
│   │   └── adr/
│   ├── api/
│   ├── guides/
│   └── design/
├── Tests/
│   ├── UnitTests/
│   ├── IntegrationTests/
│   ├── UITests/
│   └── PerformanceTests/
├── Vendor/                      # Third-party (if any)
├── fastlane/                    # Deployment automation
│   ├── Fastfile
│   ├── Appfile
│   └── Matchfile
├── .gitignore
├── .swiftlint.yml
├── Package.swift               # SPM manifest
├── Podfile                     # If using CocoaPods
├── README.md
└── LICENSE
```

## Xcode Project Configuration

### Build Configurations
```xml
<!-- Debug Configuration -->
<key>Debug</key>
<dict>
    <key>SWIFT_OPTIMIZATION_LEVEL</key>
    <string>-Onone</string>
    <key>ENABLE_TESTABILITY</key>
    <true/>
    <key>DEBUG_INFORMATION_FORMAT</key>
    <string>dwarf</string>
    <key>SWIFT_ACTIVE_COMPILATION_CONDITIONS</key>
    <string>DEBUG</string>
</dict>

<!-- Staging Configuration -->
<key>Staging</key>
<dict>
    <key>SWIFT_OPTIMIZATION_LEVEL</key>
    <string>-O</string>
    <key>ENABLE_TESTABILITY</key>
    <false/>
    <key>VALIDATE_PRODUCT</key>
    <true/>
</dict>

<!-- Release Configuration -->
<key>Release</key>
<dict>
    <key>SWIFT_OPTIMIZATION_LEVEL</key>
    <string>-Owholemodule</string>
    <key>ENABLE_BITCODE</key>
    <false/>
    <key>STRIP_INSTALLED_PRODUCT</key>
    <true/>
</dict>
```

### Build Phases
1. **Dependencies**
2. **Compile Sources**
3. **Run Script: Generate Atlases**
4. **Run Script: Compress Audio**
5. **Run Script: SwiftLint**
6. **Copy Bundle Resources**
7. **Embed Frameworks**
8. **Run Script: Upload dSYMs**

## Scaffolding Templates

### Scene Template
```swift
// Templates/Scene.swift.template
import SpriteKit
import GameCore

class {{SCENE_NAME}}Scene: BaseScene {
    // MARK: - Properties
    private var background: SKSpriteNode!
    private var interactables: [Hotspot] = []
    
    // MARK: - Scene Lifecycle
    override func didLoad() {
        super.didLoad()
        setupBackground()
        setupInteractables()
        setupAudio()
    }
    
    override func willAppear() {
        super.willAppear()
        // Preload next scene assets
    }
    
    override func didDisappear() {
        super.didDisappear()
        // Clean up resources
    }
    
    // MARK: - Setup
    private func setupBackground() {
        background = SKSpriteNode(imageNamed: "{{SCENE_NAME}}_Background")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(background)
    }
    
    private func setupInteractables() {
        // Add hotspots and interactive elements
    }
    
    private func setupAudio() {
        AudioManager.shared.playMusic(.{{SCENE_NAME}}Theme)
    }
    
    // MARK: - Interactions
    override func handleTouch(at point: CGPoint) {
        // Handle touch interactions
    }
}
```

### Component Template
```swift
// Templates/Component.swift.template
import Foundation
import GameCore

struct {{COMPONENT_NAME}}Component: Component {
    // MARK: - Properties
    weak var entity: Entity?
    
    // Component-specific properties
    {{PROPERTIES}}
    
    // MARK: - Initialization
    init({{INIT_PARAMS}}) {
        {{INIT_BODY}}
    }
    
    // MARK: - Component Logic
    {{METHODS}}
}
```

### Test Template
```swift
// Templates/Test.swift.template
import XCTest
@testable import {{MODULE_NAME}}

final class {{CLASS_NAME}}Tests: XCTestCase {
    // MARK: - Properties
    var sut: {{CLASS_NAME}}!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        sut = {{CLASS_NAME}}()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func test{{TEST_NAME}}() {
        // Given
        
        // When
        
        // Then
    }
}
```

## Scaffolding Scripts

### Create New Scene
```bash
#!/bin/bash
# Scripts/create_scene.sh

SCENE_NAME=$1
MODULE_PATH="Modules/SceneManagement"

# Create scene file from template
sed "s/{{SCENE_NAME}}/$SCENE_NAME/g" \
    Templates/Scene.swift.template > \
    "$MODULE_PATH/Sources/Scenes/${SCENE_NAME}Scene.swift"

# Create test file
sed "s/{{CLASS_NAME}}/${SCENE_NAME}Scene/g" \
    Templates/Test.swift.template > \
    "$MODULE_PATH/Tests/${SCENE_NAME}SceneTests.swift"

# Update SceneFactory
echo "Registered new scene: $SCENE_NAME"
```

### Create New Module
```bash
#!/bin/bash
# Scripts/create_module.sh

MODULE_NAME=$1
MODULE_PATH="Modules/$MODULE_NAME"

# Create module structure
mkdir -p "$MODULE_PATH"/{Sources,Tests,Resources}

# Create Package.swift for module
cat > "$MODULE_PATH/Package.swift" << EOF
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "$MODULE_NAME",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "$MODULE_NAME", targets: ["$MODULE_NAME"])
    ],
    dependencies: [],
    targets: [
        .target(name: "$MODULE_NAME", dependencies: []),
        .testTarget(name: "${MODULE_NAME}Tests", dependencies: ["$MODULE_NAME"])
    ]
)
EOF

echo "Created module: $MODULE_NAME"
```

## Build Pipeline

### Local Development
```bash
# Quick build and run
make run

# Run tests
make test

# Generate atlases
make atlases

# Full clean build
make clean build
```

### Makefile
```makefile
# Makefile
.PHONY: all build test run clean atlases

all: clean build test

build:
	xcodebuild -workspace FishPuzzles.xcworkspace \
		-scheme FishPuzzles \
		-configuration Debug \
		build

test:
	xcodebuild test \
		-workspace FishPuzzles.xcworkspace \
		-scheme FishPuzzles \
		-destination 'platform=iOS Simulator,name=iPhone 16'

run:
	xcodebuild -workspace FishPuzzles.xcworkspace \
		-scheme FishPuzzles \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)' \
		build run

atlases:
	python Scripts/generate_atlases.py

clean:
	xcodebuild clean
	rm -rf DerivedData/
	rm -rf ProcessedAssets/
```

## Git Configuration

### .gitignore
```gitignore
# Xcode
DerivedData/
*.xcuserstate
xcuserdata/

# Assets (stored in LFS or separate repo)
Assets/Art/
Assets/Audio/VO/
ProcessedAssets/

# Build artifacts
build/
*.ipa
*.dSYM.zip

# Dependencies
Pods/
.build/
Package.resolved

# Secrets
*.p12
*.mobileprovision
.env

# macOS
.DS_Store
```

### Git LFS Configuration
```gitattributes
# Large files
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.aiff filter=lfs diff=lfs merge=lfs -text
```

## Development Workflow

### Feature Branch Workflow
1. Create feature branch: `feature/JIRA-123-new-scene`
2. Implement using templates
3. Write tests (minimum 80% coverage)
4. Run local validation: `make test`
5. Create PR with checklist
6. Two reviewers required
7. CI/CD runs full test suite
8. Merge to develop
9. Automatic TestFlight build

### PR Checklist Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Performance improvement
- [ ] Refactoring

## Testing
- [ ] Unit tests pass
- [ ] UI tests pass
- [ ] Performance benchmarks met
- [ ] Tested on iPad and iPhone

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added where needed
- [ ] Documentation updated
- [ ] No warnings in Xcode
- [ ] Assets optimized
- [ ] Accessibility verified
- [ ] Memory profiled
```