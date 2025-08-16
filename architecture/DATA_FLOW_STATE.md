# Data Flow & State Management Architecture

## State Management Overview

The game uses a unidirectional data flow pattern with a centralized game state that flows down through the scene hierarchy.

```
┌─────────────────────────────────────────────────────────────┐
│                      User Input                              │
└────────────────────┬─────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  Input Processing                            │
│         (Touch, Gesture, Accessibility)                      │
└────────────────────┬─────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Action Dispatch                            │
│            (Validated, Throttled, Queued)                    │
└────────────────────┬─────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   State Reducer                              │
│          (Pure Function: State + Action → State)             │
└────────────────────┬─────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    Game State                                │
│              (Single Source of Truth)                        │
└────────┬───────────┬───────────┬────────────────────────────┘
         ▼           ▼           ▼
    ┌────────┐  ┌────────┐  ┌────────┐
    │ Scene  │  │  UI    │  │ Audio  │
    │ Update │  │ Update │  │ Update │
    └────────┘  └────────┘  └────────┘
```

## Core State Model

### GameState Structure
```swift
struct GameState: Codable {
    // Player Progress
    var currentScene: SceneID
    var completedScenes: Set<SceneID>
    var playTime: TimeInterval
    
    // Inventory
    var inventory: Inventory
    var collectedItems: Set<ItemID>
    
    // Puzzles
    var puzzleStates: [PuzzleID: PuzzleState]
    var hintsUsed: [PuzzleID: Int]
    
    // Characters
    var characterStates: [CharacterID: CharacterState]
    var dialogueHistory: [DialogueID]
    
    // Settings
    var settings: GameSettings
    
    // Transient State (not saved)
    @Transient var activeDialogue: Dialogue?
    @Transient var pendingTransition: SceneTransition?
}

struct Inventory: Codable {
    private var items: [ItemID: Item]
    var selectedItem: ItemID?
    
    mutating func add(_ item: Item)
    mutating func remove(_ itemID: ItemID)
    func canCombine(_ item1: ItemID, _ item2: ItemID) -> Bool
}

struct PuzzleState: Codable {
    enum Status {
        case locked
        case available
        case inProgress(step: Int)
        case completed
    }
    
    var status: Status
    var attempts: Int
    var timeSpent: TimeInterval
    var variant: Int // For randomized puzzles
}
```

## Action System

### Action Protocol
```swift
protocol GameAction {
    func execute(on state: inout GameState) throws
    var isReversible: Bool { get }
    func reverse(on state: inout GameState) // For undo
}

// Example Actions
struct CollectItemAction: GameAction {
    let item: Item
    let location: CGPoint
    
    func execute(on state: inout GameState) throws {
        guard !state.inventory.items.contains(item.id) else {
            throw GameError.itemAlreadyCollected
        }
        state.inventory.add(item)
        state.collectedItems.insert(item.id)
        
        // Side effects
        AudioManager.shared.playSFX(.itemCollected)
        HapticsManager.shared.trigger(.success)
    }
    
    var isReversible: Bool { true }
    
    func reverse(on state: inout GameState) {
        state.inventory.remove(item.id)
        state.collectedItems.remove(item.id)
    }
}

struct UseItemAction: GameAction {
    let itemID: ItemID
    let targetID: InteractableID
    
    func execute(on state: inout GameState) throws {
        // Validate item exists
        guard state.inventory.items[itemID] != nil else {
            throw GameError.itemNotInInventory
        }
        
        // Check if combination is valid
        let puzzle = PuzzleManager.shared.puzzleForTarget(targetID)
        guard puzzle.canUseItem(itemID) else {
            throw GameError.invalidItemUse
        }
        
        // Update state
        state.puzzleStates[puzzle.id]?.status = .completed
        state.inventory.remove(itemID)
    }
}
```

## State Manager

### Central State Coordinator
```swift
class StateManager: ObservableObject {
    // Singleton for global access
    static let shared = StateManager()
    
    // Published state for SwiftUI/Combine
    @Published private(set) var gameState: GameState
    
    // Action queue for ordered processing
    private let actionQueue = DispatchQueue(label: "game.state", qos: .userInitiated)
    
    // History for undo/redo
    private var stateHistory: [GameState] = []
    private let maxHistorySize = 10
    
    // MARK: - Action Processing
    func dispatch(_ action: GameAction) {
        actionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Store previous state for undo
            if action.isReversible {
                self.stateHistory.append(self.gameState)
                if self.stateHistory.count > self.maxHistorySize {
                    self.stateHistory.removeFirst()
                }
            }
            
            // Execute action
            do {
                try action.execute(on: &self.gameState)
                
                // Notify observers on main thread
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
                
                // Auto-save after state changes
                Task {
                    await SaveManager.shared.autoSave(self.gameState)
                }
                
            } catch {
                self.handleActionError(error, for: action)
            }
        }
    }
    
    // MARK: - Undo/Redo
    func undo() {
        guard let previousState = stateHistory.popLast() else { return }
        gameState = previousState
    }
}
```

## Scene State Flow

### Scene-Specific State
```swift
class SceneState: ObservableObject {
    // Reference to global state
    private let globalState = StateManager.shared
    
    // Scene-local state
    @Published var highlightedHotspots: Set<HotspotID> = []
    @Published var activeAnimations: Set<AnimationID> = []
    @Published var cameraPosition: CGPoint = .zero
    
    // Computed properties from global state
    var visibleItems: [Item] {
        globalState.gameState.inventory.items.values
            .filter { shouldShowInScene($0) }
    }
    
    // Scene lifecycle
    func enterScene() {
        // Initialize scene-specific state
        loadHotspots()
        startAmbientAnimations()
        
        // Subscribe to relevant state changes
        subscribeToStateChanges()
    }
    
    func exitScene() {
        // Clean up subscriptions
        // Save any scene-specific progress
    }
}
```

## Data Flow Patterns

### 1. Input → State Flow
```swift
class TouchInputHandler {
    func handleTouch(at point: CGPoint, in scene: GameScene) {
        // 1. Validate touch
        guard scene.isInteractive else { return }
        
        // 2. Find target
        if let hotspot = scene.hotspotAt(point) {
            // 3. Create action
            let action = InteractWithHotspotAction(hotspot: hotspot)
            
            // 4. Dispatch to state manager
            StateManager.shared.dispatch(action)
        }
    }
}
```

### 2. State → View Flow
```swift
class InventoryView: UIView {
    private var cancellables = Set<AnyCancellable>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Subscribe to state changes
        StateManager.shared.$gameState
            .map { $0.inventory }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inventory in
                self?.updateInventoryDisplay(inventory)
            }
            .store(in: &cancellables)
    }
    
    private func updateInventoryDisplay(_ inventory: Inventory) {
        // Update UI based on new state
    }
}
```

### 3. State → Persistence Flow
```swift
class AutoSaveManager {
    private let saveDebouncer = Debouncer(delay: 5.0)
    
    func observeStateChanges() {
        StateManager.shared.$gameState
            .sink { [weak self] state in
                self?.saveDebouncer.debounce {
                    Task {
                        await SaveManager.shared.autoSave(state)
                    }
                }
            }
            .store(in: &cancellables)
    }
}
```

## State Synchronization

### Cross-Device Sync
```swift
class StateSyncManager {
    func syncState() async throws {
        // 1. Get local state
        let localState = StateManager.shared.gameState
        
        // 2. Fetch cloud state
        let cloudState = try await CloudKitManager.shared.fetchState()
        
        // 3. Resolve conflicts
        let resolvedState = resolveConflicts(local: localState, cloud: cloudState)
        
        // 4. Update local
        StateManager.shared.updateState(resolvedState)
        
        // 5. Update cloud
        try await CloudKitManager.shared.saveState(resolvedState)
    }
    
    private func resolveConflicts(local: GameState, cloud: GameState?) -> GameState {
        guard let cloud = cloud else { return local }
        
        // Use most recent or merge strategies
        if local.lastModified > cloud.lastModified {
            return local
        } else {
            // Merge inventory and progress
            var merged = cloud
            merged.inventory = mergeInventories(local.inventory, cloud.inventory)
            merged.completedScenes = local.completedScenes.union(cloud.completedScenes)
            return merged
        }
    }
}
```

## Performance Optimization

### State Updates Batching
```swift
class BatchedStateUpdater {
    private var pendingActions: [GameAction] = []
    private let batchInterval: TimeInterval = 0.016 // 60 FPS
    private var batchTimer: Timer?
    
    func enqueue(_ action: GameAction) {
        pendingActions.append(action)
        
        if batchTimer == nil {
            batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: false) { _ in
                self.processBatch()
            }
        }
    }
    
    private func processBatch() {
        let actions = pendingActions
        pendingActions.removeAll()
        batchTimer = nil
        
        // Process all actions in one state update
        StateManager.shared.batchDispatch(actions)
    }
}
```

### Selective Re-rendering
```swift
class SceneRenderer {
    private var lastRenderedState: GameState?
    
    func render(_ state: GameState) {
        // Only re-render changed parts
        if let lastState = lastRenderedState {
            let diff = state.diff(from: lastState)
            renderDifferences(diff)
        } else {
            renderFullScene(state)
        }
        
        lastRenderedState = state
    }
    
    private func renderDifferences(_ diff: StateDiff) {
        if diff.inventoryChanged {
            updateInventoryUI()
        }
        if diff.sceneChanged {
            transitionToNewScene()
        }
        if diff.puzzleProgressChanged {
            updatePuzzleVisuals()
        }
    }
}
```

## State Validation

### State Invariants
```swift
extension GameState {
    func validate() throws {
        // Inventory constraints
        guard inventory.items.count <= GameConstants.maxInventorySize else {
            throw StateError.inventoryOverflow
        }
        
        // Scene consistency
        guard SceneManager.shared.isValidScene(currentScene) else {
            throw StateError.invalidScene
        }
        
        // Puzzle state consistency
        for (puzzleID, state) in puzzleStates {
            if state.status == .completed {
                guard !state.hintsUsed.isEmpty || state.attempts > 0 else {
                    throw StateError.inconsistentPuzzleState
                }
            }
        }
        
        // Save compatibility
        guard version == GameConstants.currentStateVersion else {
            throw StateError.incompatibleVersion
        }
    }
}
```

## Debug State Tools

### State Inspector
```swift
#if DEBUG
class StateDebugger {
    static func printState() {
        let state = StateManager.shared.gameState
        print("""
        === Game State ===
        Scene: \(state.currentScene)
        Inventory: \(state.inventory.items.count) items
        Progress: \(state.completedScenes.count)/\(SceneManager.totalScenes) scenes
        Play Time: \(state.playTime.formatted())
        ==================
        """)
    }
    
    static func exportState() -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(StateManager.shared.gameState)
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gamestate_\(Date().timeIntervalSince1970).json")
        try! data.write(to: url)
        return url
    }
    
    static func importState(from url: URL) {
        let data = try! Data(contentsOf: url)
        let state = try! JSONDecoder().decode(GameState.self, from: data)
        StateManager.shared.updateState(state)
    }
}
#endif
```

## State Migration

### Version Migration
```swift
class StateMigrator {
    static func migrate(_ state: inout GameState) throws {
        while state.version < GameConstants.currentStateVersion {
            switch state.version {
            case 1:
                try migrateV1ToV2(&state)
            case 2:
                try migrateV2ToV3(&state)
            default:
                throw StateError.unsupportedVersion
            }
        }
    }
    
    private static func migrateV1ToV2(_ state: inout GameState) throws {
        // Add new fields with defaults
        // Transform existing data
        state.version = 2
    }
}
```

## State Analytics

### Anonymous Metrics
```swift
extension GameState {
    var anonymousMetrics: [String: Any] {
        [
            "scenes_completed": completedScenes.count,
            "play_time_bucket": playTime.bucket(intervals: [300, 600, 1200, 1800]),
            "inventory_usage": Float(inventory.items.count) / Float(GameConstants.maxInventorySize),
            "hints_used": hintsUsed.values.reduce(0, +) > 0,
            "puzzle_completion_rate": Float(puzzleStates.filter { $0.value.status == .completed }.count) / Float(puzzleStates.count)
        ]
    }
}
```

## Testing State Management

### State Testing Utilities
```swift
class StateTestHelper {
    static func createMockState(
        scene: SceneID = .testScene,
        items: [Item] = [],
        completedPuzzles: [PuzzleID] = []
    ) -> GameState {
        var state = GameState()
        state.currentScene = scene
        items.forEach { state.inventory.add($0) }
        completedPuzzles.forEach { 
            state.puzzleStates[$0] = PuzzleState(status: .completed, attempts: 1, timeSpent: 60)
        }
        return state
    }
    
    static func assertStateTransition(
        from initial: GameState,
        action: GameAction,
        expected: GameState
    ) throws {
        var state = initial
        try action.execute(on: &state)
        XCTAssertEqual(state, expected)
    }
}
```