#!/bin/bash

# Fish Puzzles - Xcode Project Setup Script
# This script sets up the project structure for native Xcode development

set -e

echo "🐠 Fish Puzzles - Xcode Project Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -d "fish-puzzles/fish-puzzles.xcodeproj" ]; then
    echo -e "${RED}Error: fish-puzzles.xcodeproj not found!${NC}"
    echo "Please run this script from the fish-puzzles root directory"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found Xcode project"

# Function to create directory with message
create_dir() {
    mkdir -p "$1"
    echo -e "${GREEN}✓${NC} Created: $1"
}

# Function to create file with content
create_file() {
    echo "$2" > "$1"
    echo -e "${GREEN}✓${NC} Created: $1"
}

echo ""
echo "📁 Creating Xcode-native folder structure..."

# Clean up old SPM structure if it exists
if [ -d "fish-puzzles/Modules" ]; then
    echo "Removing old SPM Modules structure..."
    rm -rf fish-puzzles/Modules
fi

# Create Core Systems
create_dir "fish-puzzles/fish-puzzles/Core"
create_dir "fish-puzzles/fish-puzzles/Core/GameEngine"
create_dir "fish-puzzles/fish-puzzles/Core/ECS"
create_dir "fish-puzzles/fish-puzzles/Core/State"

# Create Scenes
create_dir "fish-puzzles/fish-puzzles/Scenes"
create_dir "fish-puzzles/fish-puzzles/Scenes/Base"
create_dir "fish-puzzles/fish-puzzles/Scenes/MainMenu"
create_dir "fish-puzzles/fish-puzzles/Scenes/Location1"
create_dir "fish-puzzles/fish-puzzles/Scenes/Location2"
create_dir "fish-puzzles/fish-puzzles/Scenes/Transitions"

# Create Systems
create_dir "fish-puzzles/fish-puzzles/Systems"
create_dir "fish-puzzles/fish-puzzles/Systems/Audio"
create_dir "fish-puzzles/fish-puzzles/Systems/Interaction"
create_dir "fish-puzzles/fish-puzzles/Systems/Inventory"
create_dir "fish-puzzles/fish-puzzles/Systems/Save"
create_dir "fish-puzzles/fish-puzzles/Systems/Analytics"

# Create UI
create_dir "fish-puzzles/fish-puzzles/UI"
create_dir "fish-puzzles/fish-puzzles/UI/HUD"
create_dir "fish-puzzles/fish-puzzles/UI/Menus"
create_dir "fish-puzzles/fish-puzzles/UI/Dialogue"
create_dir "fish-puzzles/fish-puzzles/UI/Components"

# Create Utilities
create_dir "fish-puzzles/fish-puzzles/Utilities"
create_dir "fish-puzzles/fish-puzzles/Utilities/Extensions"
create_dir "fish-puzzles/fish-puzzles/Utilities/Helpers"
create_dir "fish-puzzles/fish-puzzles/Utilities/Constants"

# Create Resources (keep existing)
create_dir "fish-puzzles/fish-puzzles/Resources"
create_dir "fish-puzzles/fish-puzzles/Resources/Audio"
create_dir "fish-puzzles/fish-puzzles/Resources/Atlases"
create_dir "fish-puzzles/fish-puzzles/Resources/Particles"

# Create Models
create_dir "fish-puzzles/fish-puzzles/Models"

# Create asset directories at root level
create_dir "Assets/Art/Characters"
create_dir "Assets/Art/Backgrounds"
create_dir "Assets/Art/Items"
create_dir "Assets/Art/UI"
create_dir "Assets/Audio/Music"
create_dir "Assets/Audio/VO/en"
create_dir "Assets/Audio/SFX"
create_dir "Assets/Data/Scenes"
create_dir "Assets/Data/Puzzles"
create_dir "Assets/Data/Dialogue"

# Create build support directories
create_dir "Scripts"
create_dir "Scripts/ci"
create_dir "Configuration"
create_dir "ProcessedAssets"

echo ""
echo "📝 Creating core Swift files..."

# Create GameEngine.swift
create_file "fish-puzzles/fish-puzzles/Core/GameEngine/GameEngine.swift" '//
//  GameEngine.swift
//  fish-puzzles
//
//  Core game engine that manages the game lifecycle
//

import Foundation
import SpriteKit

final class GameEngine {
    static let shared = GameEngine()
    
    private(set) var gameState: GameState
    private var sceneManager: SceneManager?
    
    private init() {
        self.gameState = GameState()
    }
    
    func start(with view: SKView) {
        sceneManager = SceneManager(view: view)
        sceneManager?.loadMainMenu()
    }
    
    func pause() {
        sceneManager?.currentScene?.isPaused = true
        gameState.isPaused = true
    }
    
    func resume() {
        sceneManager?.currentScene?.isPaused = false
        gameState.isPaused = false
    }
    
    func handleMemoryWarning() {
        AssetManager.shared.clearCache()
    }
}'

# Create GameState.swift
create_file "fish-puzzles/fish-puzzles/Core/State/GameState.swift" '//
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
}'

# Create Entity.swift for ECS
create_file "fish-puzzles/fish-puzzles/Core/ECS/Entity.swift" '//
//  Entity.swift
//  fish-puzzles
//
//  Entity-Component System base classes
//

import Foundation
import SpriteKit

class Entity {
    let id = UUID()
    private var components: [String: Component] = [:]
    weak var node: SKNode?
    
    func add<T: Component>(_ component: T) {
        let key = String(describing: type(of: component))
        components[key] = component
        component.entity = self
        component.didAddToEntity()
    }
    
    func get<T: Component>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return components[key] as? T
    }
    
    func remove<T: Component>(_ type: T.Type) {
        let key = String(describing: type)
        if let component = components.removeValue(forKey: key) {
            component.willRemoveFromEntity()
            component.entity = nil
        }
    }
    
    func update(deltaTime: TimeInterval) {
        components.values.forEach { $0.update(deltaTime: deltaTime) }
    }
}

class Component {
    weak var entity: Entity?
    
    func didAddToEntity() {
        // Override in subclasses
    }
    
    func willRemoveFromEntity() {
        // Override in subclasses
    }
    
    func update(deltaTime: TimeInterval) {
        // Override in subclasses
    }
}'

# Create SceneManager.swift
create_file "fish-puzzles/fish-puzzles/Scenes/Base/SceneManager.swift" '//
//  SceneManager.swift
//  fish-puzzles
//
//  Manages scene transitions and lifecycle
//

import Foundation
import SpriteKit

final class SceneManager {
    private weak var view: SKView?
    private(set) var currentScene: BaseGameScene?
    
    init(view: SKView) {
        self.view = view
        setupView()
    }
    
    private func setupView() {
        guard let view = view else { return }
        
        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        view.showsPhysics = false
        #endif
        
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
    }
    
    func loadMainMenu() {
        transition(to: MainMenuScene(size: view?.bounds.size ?? CGSize(width: 1024, height: 768)))
    }
    
    func loadScene(_ sceneID: String) {
        // Scene factory would go here
        switch sceneID {
        case "Location1":
            transition(to: Location1Scene(size: view?.bounds.size ?? CGSize(width: 1024, height: 768)))
        case "Location2":
            transition(to: Location2Scene(size: view?.bounds.size ?? CGSize(width: 1024, height: 768)))
        default:
            loadMainMenu()
        }
    }
    
    private func transition(to scene: BaseGameScene, transition: SKTransition = .fade(withDuration: 1.0)) {
        currentScene = scene
        view?.presentScene(scene, transition: transition)
    }
}'

# Create BaseGameScene.swift
create_file "fish-puzzles/fish-puzzles/Scenes/Base/BaseGameScene.swift" '//
//  BaseGameScene.swift
//  fish-puzzles
//
//  Base class for all game scenes
//

import SpriteKit

class BaseGameScene: SKScene {
    var entities: [Entity] = []
    var interactionSystem: InteractionSystem!
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
    }
    
    func setupScene() {
        // Override in subclasses
        interactionSystem = InteractionSystem(scene: self)
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - (lastUpdateTime ?? currentTime)
        lastUpdateTime = currentTime
        
        entities.forEach { $0.update(deltaTime: deltaTime) }
    }
    
    private var lastUpdateTime: TimeInterval?
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        interactionSystem?.handleTouch(at: location)
    }
}'

# Create AudioManager.swift
create_file "fish-puzzles/fish-puzzles/Systems/Audio/AudioManager.swift" '//
//  AudioManager.swift
//  fish-puzzles
//
//  Manages all audio playback
//

import AVFoundation
import SpriteKit

final class AudioManager {
    static let shared = AudioManager()
    
    private var musicPlayer: AVAudioPlayer?
    private var voicePlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func playMusic(_ filename: String, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "m4a") else { return }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = volume * GameEngine.shared.gameState.musicVolume
            musicPlayer?.play()
        } catch {
            print("Failed to play music: \(error)")
        }
    }
    
    func playSFX(_ filename: String, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "wav") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume * GameEngine.shared.gameState.sfxVolume
            player.play()
            sfxPlayers.append(player)
            
            // Clean up finished players
            sfxPlayers.removeAll { !$0.isPlaying }
        } catch {
            print("Failed to play SFX: \(error)")
        }
    }
    
    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }
}'

# Create SaveManager.swift
create_file "fish-puzzles/fish-puzzles/Systems/Save/SaveManager.swift" '//
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
}'

# Create InteractionSystem.swift
create_file "fish-puzzles/fish-puzzles/Systems/Interaction/InteractionSystem.swift" '//
//  InteractionSystem.swift
//  fish-puzzles
//
//  Handles touch interactions and hotspots
//

import SpriteKit

struct Hotspot {
    let id: String
    let frame: CGRect
    let action: () -> Void
    
    func contains(_ point: CGPoint) -> Bool {
        frame.contains(point)
    }
}

final class InteractionSystem {
    weak var scene: BaseGameScene?
    private var hotspots: [Hotspot] = []
    
    init(scene: BaseGameScene) {
        self.scene = scene
    }
    
    func registerHotspot(_ hotspot: Hotspot) {
        hotspots.append(hotspot)
    }
    
    func removeHotspot(id: String) {
        hotspots.removeAll { $0.id == id }
    }
    
    func handleTouch(at point: CGPoint) {
        // Check hotspots
        for hotspot in hotspots {
            if hotspot.contains(point) {
                hotspot.action()
                AudioManager.shared.playSFX("tap")
                return
            }
        }
        
        // Check entities with interaction components
        scene?.entities.forEach { entity in
            guard let node = entity.node,
                  let _ = entity.get(InteractableComponent.self) else { return }
            
            if node.contains(point) {
                handleEntityInteraction(entity)
            }
        }
    }
    
    private func handleEntityInteraction(_ entity: Entity) {
        // Handle entity interaction
        if let interactable = entity.get(InteractableComponent.self) {
            interactable.interact()
        }
    }
}'

# Create sample scenes
create_file "fish-puzzles/fish-puzzles/Scenes/MainMenu/MainMenuScene.swift" '//
//  MainMenuScene.swift
//  fish-puzzles
//
//  Main menu scene
//

import SpriteKit

class MainMenuScene: BaseGameScene {
    override func setupScene() {
        super.setupScene()
        
        // Background
        let background = SKSpriteNode(color: .systemBlue, size: size)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(background)
        
        // Title
        let title = SKLabelNode(text: "Fish Puzzles")
        title.fontSize = 48
        title.fontName = "Helvetica-Bold"
        title.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        addChild(title)
        
        // Play button
        let playButton = SKSpriteNode(color: .systemGreen, size: CGSize(width: 200, height: 60))
        playButton.position = CGPoint(x: size.width/2, y: size.height * 0.4)
        playButton.name = "playButton"
        addChild(playButton)
        
        let playLabel = SKLabelNode(text: "Play")
        playLabel.fontSize = 32
        playLabel.fontName = "Helvetica"
        playLabel.verticalAlignmentMode = .center
        playButton.addChild(playLabel)
        
        // Register hotspot for play button
        let playHotspot = Hotspot(
            id: "play",
            frame: playButton.frame,
            action: { [weak self] in
                self?.startGame()
            }
        )
        interactionSystem.registerHotspot(playHotspot)
        
        // Play menu music
        AudioManager.shared.playMusic("menu_theme")
    }
    
    private func startGame() {
        SceneManager(view: view!).loadScene("Location1")
    }
}'

create_file "fish-puzzles/fish-puzzles/Scenes/Location1/Location1Scene.swift" '//
//  Location1Scene.swift
//  fish-puzzles
//
//  First location in the game
//

import SpriteKit

class Location1Scene: BaseGameScene {
    private var fishCharacter: SKSpriteNode!
    
    override func setupScene() {
        super.setupScene()
        
        // Background - will be replaced with actual art
        let background = SKSpriteNode(color: .cyan, size: size)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
        
        // Add fish character
        setupCharacter()
        
        // Setup hotspots
        setupHotspots()
        
        // Play underwater ambience
        AudioManager.shared.playMusic("underwater_ambience")
    }
    
    private func setupCharacter() {
        fishCharacter = SKSpriteNode(color: .orange, size: CGSize(width: 60, height: 40))
        fishCharacter.position = CGPoint(x: size.width * 0.2, y: size.height * 0.5)
        fishCharacter.name = "player"
        addChild(fishCharacter)
        
        // Add slight floating animation
        let floatUp = SKAction.moveBy(x: 0, y: 10, duration: 2)
        let floatDown = SKAction.moveBy(x: 0, y: -10, duration: 2)
        let sequence = SKAction.sequence([floatUp, floatDown])
        fishCharacter.run(SKAction.repeatForever(sequence))
    }
    
    private func setupHotspots() {
        // Example: Treasure chest hotspot
        let chestHotspot = Hotspot(
            id: "treasure_chest",
            frame: CGRect(x: size.width * 0.7, y: size.height * 0.3, width: 100, height: 100),
            action: { [weak self] in
                self?.openTreasureChest()
            }
        )
        interactionSystem.registerHotspot(chestHotspot)
    }
    
    private func openTreasureChest() {
        print("Opening treasure chest!")
        AudioManager.shared.playSFX("chest_open")
        
        // Add item to inventory
        let pearl = Item(id: "pearl", name: "Shiny Pearl", imageName: "pearl")
        GameEngine.shared.gameState.inventory.add(pearl)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // Move character to touch location
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let moveAction = SKAction.move(to: location, duration: 1.0)
        fishCharacter.run(moveAction)
    }
}'

create_file "fish-puzzles/fish-puzzles/Scenes/Location2/Location2Scene.swift" '//
//  Location2Scene.swift
//  fish-puzzles
//
//  Second location in the game
//

import SpriteKit

class Location2Scene: BaseGameScene {
    override func setupScene() {
        super.setupScene()
        
        // Background
        let background = SKSpriteNode(color: .blue, size: size)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
        
        // Add scene-specific content here
    }
}'

# Create a component example
create_file "fish-puzzles/fish-puzzles/Core/ECS/InteractableComponent.swift" '//
//  InteractableComponent.swift
//  fish-puzzles
//
//  Component for interactive entities
//

import Foundation

class InteractableComponent: Component {
    var interactionRadius: CGFloat = 50
    var requiredItem: String?
    var onInteract: (() -> Void)?
    
    func interact() {
        // Check if we have required item
        if let requiredItem = requiredItem {
            guard GameEngine.shared.gameState.inventory.contains(requiredItem) else {
                print("Need item: \(requiredItem)")
                return
            }
        }
        
        onInteract?()
    }
}'

# Create AssetManager
create_file "fish-puzzles/fish-puzzles/Utilities/Helpers/AssetManager.swift" '//
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
}'

echo ""
echo "📝 Updating configuration files..."

# Update .gitignore
create_file "fish-puzzles/.gitignore" '# Xcode
build/
DerivedData/
*.xcuserstate
xcuserdata/
*.xccheckout
*.moved-aside
*.xcuserstate

# macOS
.DS_Store

# Assets (use Git LFS for large files)
*.png
*.jpg
*.wav
*.mp3
*.m4a

# Secrets
*.p12
*.mobileprovision
.env'

echo ""
echo -e "${GREEN}✅ Xcode project structure created!${NC}"
echo ""
echo "📚 Next steps:"
echo "  1. Open fish-puzzles.xcodeproj in Xcode"
echo "  2. Add the new Swift files to your project:"
echo "     - Select all files in fish-puzzles/fish-puzzles/"
echo "     - Drag them into Xcode project navigator"
echo "     - Make sure 'Copy items if needed' is unchecked"
echo "     - Add to target: fish-puzzles"
echo "  3. Build and run to test (⌘+R)"
echo ""
echo "📁 Project Structure:"
echo "  Core/          - Game engine, ECS, state management"
echo "  Scenes/        - All game scenes"
echo "  Systems/       - Audio, saves, interactions, etc."
echo "  UI/            - HUD, menus, dialogue"
echo "  Utilities/     - Helpers and extensions"
echo ""
echo "🎮 The game now has:"
echo "  - Main menu scene"
echo "  - Basic game scenes"
echo "  - Touch interaction system"
echo "  - Audio manager"
echo "  - Save system ready for CloudKit"
echo "  - ECS for game objects"
echo ""
echo "🐠 Happy coding!"