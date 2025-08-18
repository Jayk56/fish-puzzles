//
//  BaseGameScene.swift
//  fish-puzzles
//
//  Base class for all game scenes
//

import SpriteKit

class BaseGameScene: SKScene {
    var entities: [Entity] = []
    var interactionSystem: InteractionSystem!
    var hudManager: HUDManager?
    var dragDropSystem: DragDropSystem?
    var currentPuzzle: Puzzle?
    
    // Safe area management
    var showSafeAreaDebug = false
    private var safeAreaDebugNode: SKNode?
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
        setupSystems()
    }
    
    func setupScene() {
        // Override in subclasses
        interactionSystem = InteractionSystem(scene: self)
        
        // Initialize HUD for game scenes (not for menu)
        if !(self is MainMenuScene) {
            hudManager = HUDManager(scene: self)
            setupHUD()
        }
        
        // Setup safe area debugging if enabled
        if showSafeAreaDebug {
            enableSafeAreaDebug()
        }
    }
    
    func setupSystems() {
        // Setup drag and drop
        dragDropSystem = DragDropSystem.shared
        dragDropSystem?.scene = self
        dragDropSystem?.inventoryBar = hudManager?.inventoryBar
        
        // Setup inventory connections
        InventoryManager.shared.persistentBar = hudManager?.inventoryBar
        InventoryManager.shared.interactionEngine = ItemInteractionEngine.shared
        
        // Setup hint system
        ProgressiveHintSystem.shared.scene = self
        if let puzzle = currentPuzzle {
            ProgressiveHintSystem.shared.setPuzzle(puzzle)
        }
    }
    
    func setupHUD() {
        // Override in subclasses to configure HUD
        setupInventoryBar()
    }
    
    func setupInventoryBar() {
        // Connect inventory bar callbacks
        hudManager?.inventoryBar?.onItemSelected = { [weak self] item in
            self?.handleItemSelection(item)
        }
        
        hudManager?.inventoryBar?.onItemDragStart = { [weak self] item, point in
            // Drag start is handled by touchesBegan
            self?.dragDropSystem?.draggedItem = item
        }
        
        hudManager?.inventoryBar?.onItemDragEnd = { [weak self] item, point in
            // Drag end is handled by touchesEnded
            _ = item  // Suppress warning
        }
    }
    
    func handleItemSelection(_ item: Item?) {
        // Visual feedback for selection
        if let item = item {
            VisualFeedbackSystem.shared.showInteractionFeedback(
                at: CGPoint(x: size.width / 2, y: 100),
                type: .use
            )
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - (lastUpdateTime ?? currentTime)
        lastUpdateTime = currentTime
        
        entities.forEach { $0.update(deltaTime: deltaTime) }
        hudManager?.update(deltaTime: deltaTime)
        
        // Update hotspot highlights based on player position
        if let playerPosition = getPlayerPosition() {
            interactionSystem?.updateHotspotHighlights(playerPosition: playerPosition)
        }
    }
    
    private var lastUpdateTime: TimeInterval?
    
    func getPlayerPosition() -> CGPoint? {
        // Override in subclasses to return actual player position
        return CGPoint(x: size.width / 2, y: size.height / 2)
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if drag system wants to handle it
        if dragDropSystem?.handleTouchBegan(touch, in: self) == true {
            return
        }
        
        // With proper isUserInteractionEnabled, touches will be handled by:
        // 1. HUD buttons (highest z-position, isUserInteractionEnabled = true)
        // 2. HUD overlays (in HUDContainer, isUserInteractionEnabled = true)
        // 3. Game hotspots (treasure chest, doors, etc.)
        // 4. Scene itself (for movement)
        
        // Only check game interactions (non-HUD hotspots)
        if let handled = interactionSystem?.handleTouch(at: location), handled {
            return  // A game hotspot was touched
        }
        
        // If nothing handled it, subclasses can process (e.g., move character)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Handle drag and drop
        dragDropSystem?.handleTouchMoved(touch, in: self)
        
        // Update item cursor if needed
        interactionSystem?.handleTouchMoved(touch)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Handle drag and drop
        dragDropSystem?.handleTouchEnded(touch, in: self)
    }
    
    // MARK: - Safe Area Management
    
    func enableSafeAreaDebug() {
        safeAreaDebugNode?.removeFromParent()
        safeAreaDebugNode = SafeAreaManager.shared.createDebugOverlay(for: self)
        if let debugNode = safeAreaDebugNode {
            addChild(debugNode)
        }
        showSafeAreaDebug = true
    }
    
    func disableSafeAreaDebug() {
        safeAreaDebugNode?.removeFromParent()
        safeAreaDebugNode = nil
        showSafeAreaDebug = false
    }
    
    /// Position a node within the safe gameplay area using normalized coordinates (0-1)
    func positionInSafeArea(_ node: SKNode, normalizedX: CGFloat, normalizedY: CGFloat) {
        node.position = safePosition(normalizedX: normalizedX, normalizedY: normalizedY)
    }
    
    /// Create a background that fits the safe gameplay area
    func createSafeBackground(color: UIColor = .cyan) -> SKSpriteNode {
        let safeArea = safeGameplayArea
        let background = SKSpriteNode(color: color, size: safeArea.size)
        background.position = CGPoint(x: safeArea.midX, y: safeArea.midY)
        background.zPosition = -1
        return background
    }
    
    /// Check if a position is within the safe gameplay area
    func isPositionSafe(_ position: CGPoint) -> Bool {
        return SafeAreaManager.shared.isInSafeArea(point: position, sceneSize: size)
    }
    
    /// Get the ground level Y position (just above inventory bar)
    var groundLevel: CGFloat {
        return SafeAreaManager.shared.groundLevel(for: size)
    }
    
    /// Get the sky level Y position (top of safe area)
    var skyLevel: CGFloat {
        return SafeAreaManager.shared.skyLevel(for: size)
    }
}
