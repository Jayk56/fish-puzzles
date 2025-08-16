#!/bin/bash

SCENE_NAME=$1

if [ -z "$SCENE_NAME" ]; then
    echo "Usage: ./create_scene.sh SceneName"
    exit 1
fi

echo "Creating scene: $SCENE_NAME"

# Create scene directory if it doesn't exist
mkdir -p "fish-puzzles/Scenes/${SCENE_NAME}"

# Create scene file
cat > "fish-puzzles/Scenes/${SCENE_NAME}/${SCENE_NAME}Scene.swift" << EOF
import SpriteKit

class ${SCENE_NAME}Scene: BaseGameScene {
    // MARK: - Properties
    private var background: SKSpriteNode!
    private var hotspots: [Hotspot] = []
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
    }
    
    private func setupScene() {
        // Setup background
        background = SKSpriteNode(imageNamed: "${SCENE_NAME}_bg")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(background)
        
        // Setup hotspots
        setupHotspots()
        
        // Setup audio
        AudioManager.shared.playMusic("${SCENE_NAME}Theme")
    }
    
    private func setupHotspots() {
        // Add interactive elements
    }
    
    // MARK: - Interactions
    override func handleTouch(at point: CGPoint) {
        // Handle touch interactions
    }
}
EOF

# Create test directory if it doesn't exist
mkdir -p "fish-puzzlesTests/Scenes"

# Create test file
cat > "fish-puzzlesTests/Scenes/${SCENE_NAME}SceneTests.swift" << EOF
import XCTest
@testable import fish_puzzles

final class ${SCENE_NAME}SceneTests: XCTestCase {
    var scene: ${SCENE_NAME}Scene!
    
    override func setUp() {
        super.setUp()
        scene = ${SCENE_NAME}Scene(size: CGSize(width: 1024, height: 768))
    }
    
    override func tearDown() {
        scene = nil
        super.tearDown()
    }
    
    func testSceneInitialization() {
        XCTAssertNotNil(scene)
        XCTAssertEqual(scene.size.width, 1024)
        XCTAssertEqual(scene.size.height, 768)
    }
}
EOF

echo "✓ Created ${SCENE_NAME}Scene.swift in fish-puzzles/Scenes/${SCENE_NAME}/"
echo "✓ Created ${SCENE_NAME}SceneTests.swift in fish-puzzlesTests/Scenes/"
echo ""
echo "Remember to add these files to your Xcode project:"
echo "1. Drag the new scene file into Xcode under Scenes group"
echo "2. Drag the test file into Xcode under the test target"
