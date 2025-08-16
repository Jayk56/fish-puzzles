# Implementation Guide - Quick Start

## Core Implementation Examples

### 1. Basic Scene Implementation

```swift
// Location1Scene.swift
import SpriteKit
import GameCore

class Location1Scene: BaseGameScene {
    // MARK: - Properties
    private var background: SKSpriteNode!
    private var fishCharacter: CharacterNode!
    private var hotspots: [Hotspot] = []
    private var sceneState: Location1State!
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
        subscribeToState()
    }
    
    private func setupScene() {
        // Background
        background = SKSpriteNode(texture: AssetLoader.shared.texture("location1_bg"))
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = Layers.background
        addChild(background)
        
        // Character
        fishCharacter = CharacterNode(characterID: .mainFish)
        fishCharacter.position = CGPoint(x: 200, y: 300)
        fishCharacter.zPosition = Layers.characters
        addChild(fishCharacter)
        
        // Hotspots
        setupHotspots()
        
        // Audio
        AudioManager.shared.playMusic(.underwater, fadeIn: 2.0)
    }
    
    private func setupHotspots() {
        // Treasure chest hotspot
        let chest = Hotspot(
            id: "treasure_chest",
            frame: CGRect(x: 400, y: 200, width: 100, height: 100),
            action: { [weak self] in
                self?.handleChestInteraction()
            }
        )
        hotspots.append(chest)
        
        // Exit to next scene
        let exit = Hotspot(
            id: "cave_entrance",
            frame: CGRect(x: 700, y: 300, width: 150, height: 200),
            action: { [weak self] in
                self?.transitionToScene(.location2)
            }
        )
        hotspots.append(exit)
    }
    
    // MARK: - Interactions
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check hotspots
        for hotspot in hotspots {
            if hotspot.contains(location) {
                hotspot.trigger()
                return
            }
        }
        
        // Move character
        fishCharacter.swim(to: location)
    }
    
    private func handleChestInteraction() {
        let action = OpenChestAction(chestID: "treasure_chest")
        StateManager.shared.dispatch(action)
    }
}
```

### 2. ECS Component Implementation

```swift
// Components/InteractableComponent.swift
import Foundation

struct InteractableComponent: Component {
    weak var entity: Entity?
    
    let interactionRadius: CGFloat
    let requiredItem: ItemID?
    let onInteract: (Entity) -> Void
    
    func canInteract(with inventory: Inventory) -> Bool {
        if let requiredItem = requiredItem {
            return inventory.contains(requiredItem)
        }
        return true
    }
}

// Components/SpriteComponent.swift
struct SpriteComponent: Component {
    weak var entity: Entity?
    
    let node: SKSpriteNode
    var texture: SKTexture {
        didSet { node.texture = texture }
    }
    var position: CGPoint {
        didSet { node.position = position }
    }
}

// Entity setup
class TreasureChestEntity: Entity {
    init(position: CGPoint) {
        super.init()
        
        // Sprite
        let sprite = SKSpriteNode(imageNamed: "chest_closed")
        sprite.position = position
        add(SpriteComponent(node: sprite, texture: sprite.texture!, position: position))
        
        // Interaction
        add(InteractableComponent(
            interactionRadius: 50,
            requiredItem: .key,
            onInteract: { [weak self] _ in
                self?.open()
            }
        ))
        
        // Inventory component for contained items
        add(InventoryComponent(items: [.goldCoin, .pearl]))
    }
    
    private func open() {
        // Change sprite
        if let sprite = get(SpriteComponent.self) {
            sprite.texture = SKTexture(imageNamed: "chest_open")
        }
        
        // Give items to player
        if let inventory = get(InventoryComponent.self) {
            for item in inventory.items {
                StateManager.shared.dispatch(CollectItemAction(item: item))
            }
        }
    }
}
```

### 3. State Management Implementation

```swift
// State/GameState.swift
struct GameState: Codable, Equatable {
    // Core state
    var currentScene: SceneID = .mainMenu
    var inventory: Inventory = Inventory()
    var flags: Set<GameFlag> = []
    var puzzles: [PuzzleID: PuzzleState] = [:]
    
    // Progress tracking
    var playTime: TimeInterval = 0
    var scenesVisited: Set<SceneID> = []
    var itemsCollected: Set<ItemID> = []
    
    // Settings
    var settings: GameSettings = GameSettings()
    
    // Computed properties
    var progress: Float {
        Float(scenesVisited.count) / Float(SceneID.allCases.count)
    }
}

// State/StateManager.swift
class StateManager: ObservableObject {
    static let shared = StateManager()
    
    @Published private(set) var state = GameState()
    private let stateQueue = DispatchQueue(label: "state.queue", qos: .userInitiated)
    
    func dispatch(_ action: GameAction) {
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            
            var newState = self.state
            action.execute(on: &newState)
            
            DispatchQueue.main.async {
                self.state = newState
                self.saveState()
            }
        }
    }
    
    private func saveState() {
        Task {
            await SaveManager.shared.autoSave(state)
        }
    }
}

// Actions/CollectItemAction.swift
struct CollectItemAction: GameAction {
    let item: Item
    
    func execute(on state: inout GameState) {
        state.inventory.add(item)
        state.itemsCollected.insert(item.id)
        
        // Side effects
        AudioManager.shared.playSFX(.itemCollected)
        HapticsManager.shared.play(.success)
        
        // Check achievements
        if state.itemsCollected.count >= 10 {
            state.flags.insert(.collectorAchievement)
        }
    }
}
```

### 4. Save System Implementation

```swift
// Save/SaveManager.swift
import CloudKit

class SaveManager {
    static let shared = SaveManager()
    
    private let container = CKContainer(identifier: "iCloud.com.company.fishpuzzles")
    private let privateDB: CKDatabase
    
    init() {
        privateDB = container.privateCloudDatabase
    }
    
    // MARK: - Local Save
    func saveLocal(_ state: GameState, to slot: SaveSlot) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        
        let url = getSaveURL(for: slot)
        try data.write(to: url)
        
        // Update metadata
        let metadata = SaveMetadata(
            slot: slot,
            timestamp: Date(),
            playTime: state.playTime,
            progress: state.progress,
            scene: state.currentScene
        )
        try await saveMetadata(metadata)
    }
    
    // MARK: - Cloud Sync
    func syncToCloud(_ state: GameState) async throws {
        let record = CKRecord(recordType: "SaveGame")
        record["data"] = try JSONEncoder().encode(state)
        record["timestamp"] = Date()
        record["deviceID"] = UIDevice.current.identifierForVendor?.uuidString
        
        try await privateDB.save(record)
    }
    
    func loadFromCloud() async throws -> GameState? {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "SaveGame", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let results = try await privateDB.records(matching: query)
        guard let record = results.matchResults.first?.0,
              let data = record["data"] as? Data else {
            return nil
        }
        
        return try JSONDecoder().decode(GameState.self, from: data)
    }
    
    // MARK: - Conflict Resolution
    func resolveConflict(local: GameState, cloud: GameState) -> GameState {
        // Take the state with more progress
        if local.progress > cloud.progress {
            return local
        } else if cloud.progress > local.progress {
            return cloud
        } else {
            // Same progress, use most recent
            return local.playTime > cloud.playTime ? local : cloud
        }
    }
}
```

### 5. Audio System Implementation

```swift
// Audio/AudioManager.swift
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    private var musicPlayer: AVAudioPlayer?
    private var voiceOverPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    private let sfxQueue = DispatchQueue(label: "audio.sfx", qos: .userInitiated)
    
    // MARK: - Music
    func playMusic(_ track: MusicTrack, fadeIn: TimeInterval = 0) {
        guard let url = Bundle.main.url(forResource: track.filename, withExtension: "m4a") else {
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = 0
            musicPlayer?.play()
            
            if fadeIn > 0 {
                musicPlayer?.setVolume(settings.musicVolume, fadeDuration: fadeIn)
            } else {
                musicPlayer?.volume = settings.musicVolume
            }
        } catch {
            print("Failed to play music: \(error)")
        }
    }
    
    // MARK: - Voice Over
    func playVO(_ line: VOLine) async {
        let language = LocalizationManager.shared.currentLanguage
        let filename = "\(line.id)_\(language)"
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "m4a") else {
            print("VO file not found: \(filename)")
            return
        }
        
        do {
            voiceOverPlayer = try AVAudioPlayer(contentsOf: url)
            voiceOverPlayer?.volume = settings.voiceVolume
            voiceOverPlayer?.play()
            
            // Show subtitles
            SubtitleManager.shared.show(line.text)
            
            // Wait for completion
            await withCheckedContinuation { continuation in
                voiceOverPlayer?.delegate = AudioPlayerDelegate {
                    continuation.resume()
                }
            }
        } catch {
            print("Failed to play VO: \(error)")
        }
    }
    
    // MARK: - Sound Effects
    func playSFX(_ effect: SoundEffect, at position: CGPoint? = nil) {
        sfxQueue.async { [weak self] in
            guard let url = Bundle.main.url(forResource: effect.filename, withExtension: "wav") else {
                return
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = self?.settings.sfxVolume ?? 1.0
                
                // Spatial audio for positioned sounds
                if let position = position {
                    player.pan = self?.calculatePan(for: position) ?? 0
                }
                
                player.play()
                self?.sfxPlayers.append(player)
                
                // Clean up finished players
                self?.sfxPlayers.removeAll { !$0.isPlaying }
            } catch {
                print("Failed to play SFX: \(error)")
            }
        }
    }
}
```

### 6. Asset Loading Implementation

```swift
// Assets/AssetLoader.swift
class AssetLoader {
    static let shared = AssetLoader()
    
    private let cache = NSCache<NSString, SKTexture>()
    private let loadQueue = DispatchQueue(label: "assets.load", qos: .userInitiated)
    
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 200 * 1024 * 1024 // 200MB
    }
    
    // MARK: - Texture Loading
    func texture(_ name: String) -> SKTexture {
        // Check cache
        if let cached = cache.object(forKey: name as NSString) {
            return cached
        }
        
        // Load texture
        let texture = SKTexture(imageNamed: name)
        texture.preload {
            self.cache.setObject(texture, forKey: name as NSString, cost: texture.size().memorySize)
        }
        
        return texture
    }
    
    // MARK: - Atlas Loading
    func atlas(_ name: String) async -> SKTextureAtlas {
        return await withCheckedContinuation { continuation in
            let atlas = SKTextureAtlas(named: name)
            atlas.preload {
                continuation.resume(returning: atlas)
            }
        }
    }
    
    // MARK: - Scene Preloading
    func preloadScene(_ sceneID: SceneID) {
        loadQueue.async {
            let manifest = self.loadManifest(for: sceneID)
            
            // Preload textures
            for textureName in manifest.textures {
                _ = self.texture(textureName)
            }
            
            // Preload audio
            for audioFile in manifest.audio {
                AudioManager.shared.preload(audioFile)
            }
        }
    }
    
    // MARK: - Memory Management
    func handleMemoryWarning() {
        cache.removeAllObjects()
        
        // Keep only current scene assets
        if let currentScene = StateManager.shared.state.currentScene {
            preloadScene(currentScene)
        }
    }
}

// Helper extension
extension CGSize {
    var memorySize: Int {
        Int(width * height * 4) // RGBA
    }
}
```

### 7. Privacy-Safe Analytics

```swift
// Analytics/PrivacyAnalytics.swift
class PrivacyAnalytics {
    static let shared = PrivacyAnalytics()
    
    private var events: [GameEvent] = []
    private let eventQueue = DispatchQueue(label: "analytics.queue")
    
    // MARK: - Event Logging
    func log(_ event: GameEvent) {
        guard UserDefaults.standard.bool(forKey: "analytics_enabled") else { return }
        
        eventQueue.async { [weak self] in
            // Apply differential privacy
            let noisyEvent = self?.addNoise(to: event) ?? event
            self?.events.append(noisyEvent)
            
            // Batch upload every 100 events
            if self?.events.count ?? 0 >= 100 {
                self?.uploadBatch()
            }
        }
    }
    
    private func addNoise(to event: GameEvent) -> GameEvent {
        var noisyEvent = event
        
        // Add Laplace noise to numeric values
        if let duration = event.data["duration"] as? TimeInterval {
            let noise = LaplaceDistribution.sample(scale: 5.0)
            noisyEvent.data["duration"] = max(0, duration + noise)
        }
        
        // Generalize precise values
        if let count = event.data["count"] as? Int {
            noisyEvent.data["count_bucket"] = bucketize(count, buckets: [0, 1, 5, 10, 20, 50])
            noisyEvent.data.removeValue(forKey: "count")
        }
        
        return noisyEvent
    }
    
    private func uploadBatch() {
        let batch = events
        events.removeAll()
        
        // Aggregate before sending
        let aggregated = aggregate(batch)
        
        // Send to privacy-safe endpoint (no user identification)
        // This would be your own backend that further aggregates data
    }
}
```

## Testing Patterns

### Unit Test Example
```swift
import XCTest
@testable import FishPuzzles

class InventoryTests: XCTestCase {
    var inventory: Inventory!
    
    override func setUp() {
        super.setUp()
        inventory = Inventory()
    }
    
    func testAddItem() {
        // Given
        let item = Item(id: .pearl, name: "Pearl", icon: "pearl_icon")
        
        // When
        inventory.add(item)
        
        // Then
        XCTAssertTrue(inventory.contains(item.id))
        XCTAssertEqual(inventory.items.count, 1)
    }
    
    func testCombineItems() {
        // Given
        inventory.add(Item(id: .seaweed))
        inventory.add(Item(id: .shell))
        
        // When
        let result = inventory.combine(.seaweed, with: .shell)
        
        // Then
        XCTAssertEqual(result?.id, .seaweedRope)
        XCTAssertFalse(inventory.contains(.seaweed))
        XCTAssertFalse(inventory.contains(.shell))
        XCTAssertTrue(inventory.contains(.seaweedRope))
    }
}
```

## Performance Monitoring

```swift
// Debug/PerformanceMonitor.swift
#if DEBUG
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFTimeInterval = 0
    private var frameDrops = 0
    
    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func tick(_ displayLink: CADisplayLink) {
        let frameDuration = displayLink.timestamp - lastFrameTime
        lastFrameTime = displayLink.timestamp
        
        // Check for frame drops (target 60 FPS = 16.67ms)
        if frameDuration > 0.020 { // 20ms threshold
            frameDrops += 1
            print("⚠️ Frame drop: \(frameDuration * 1000)ms")
        }
        
        // Report every second
        if displayLink.timestamp.truncatingRemainder(dividingBy: 1.0) < 0.016 {
            let fps = 1.0 / frameDuration
            print("📊 FPS: \(Int(fps)), Drops: \(frameDrops)")
            frameDrops = 0
        }
    }
}
#endif
```

## Getting Started Checklist

- [ ] Set up Xcode project with modular structure
- [ ] Configure SpriteKit and CloudKit capabilities
- [ ] Implement base scene and game loop
- [ ] Set up ECS for game objects
- [ ] Create state management system
- [ ] Implement save/load functionality
- [ ] Add audio system
- [ ] Set up asset pipeline
- [ ] Configure privacy-safe analytics
- [ ] Add parental gates
- [ ] Test on multiple devices
- [ ] Profile memory and performance
- [ ] Verify COPPA compliance
- [ ] Prepare for App Store submission