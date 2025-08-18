//
//  HUDManager.swift
//  fish-puzzles
//
//  Central coordinator for UI overlays
//

import SpriteKit

class HUDManager {
    enum OverlayType: Int, CaseIterable {
        case gameWorld = 0
        case persistentHUD = 50  // Always-visible inventory bar
        case hud = 100
        case inventory = 200
        case map = 201
        case dialogue = 300
        case hint = 400
        case settings = 500
        case pause = 600
        
        var zPosition: CGFloat {
            return CGFloat(self.rawValue)
        }
    }
    
    weak var scene: SKScene?
    private(set) var overlays: [OverlayType: UIOverlay] = [:]
    private var activeOverlays: Set<OverlayType> = []
    private var overlayContainer: HUDContainer
    
    private var persistentInventoryBar: PersistentInventoryBar?
    private var persistentElements: [SKNode] = []
    
    init(scene: SKScene) {
        self.scene = scene
        self.overlayContainer = HUDContainer()
        self.overlayContainer.hudManager = self
        // Position container at center of scene for proper overlay positioning
        overlayContainer.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        overlayContainer.zPosition = 1000  // Ensure HUD is above game elements
        scene.addChild(overlayContainer)
        
        setupOverlays()
        setupPersistentElements()
    }
    
    private func setupOverlays() {
        guard let scene = scene else { return }
        
        overlays[.inventory] = InventoryOverlay(size: scene.size)
        overlays[.map] = MapOverlay(size: scene.size)
        overlays[.dialogue] = DialogueOverlay(size: scene.size)
        overlays[.hint] = HintOverlay(size: scene.size)
        overlays[.settings] = SettingsOverlay(size: scene.size)
        
        for (type, overlay) in overlays {
            if let node = overlay as? SKNode {
                node.zPosition = type.zPosition
                node.isHidden = true
                overlayContainer.addChild(node)
            }
        }
    }
    
    private func setupPersistentElements() {
        guard let scene = scene else { return }
        
        persistentInventoryBar = PersistentInventoryBar(size: scene.size)
        persistentInventoryBar?.zPosition = 1100  // Higher than overlayContainer (1000) to ensure it's always on top
        persistentInventoryBar?.hudManager = self
        
        if let inventoryBar = persistentInventoryBar {
            // Add directly to scene instead of overlay container to avoid rendering issues
            scene.addChild(inventoryBar)
            persistentElements.append(inventoryBar)
        }
    }
    
    var inventoryBar: PersistentInventoryBar? {
        return persistentInventoryBar
    }
    
    func show(_ type: OverlayType, animated: Bool = true) {
        guard let overlay = overlays[type] else { return }
        
        activeOverlays.insert(type)
        overlay.show(animated: animated)
        
        if overlay.dimBackground {
            addBackgroundDim(below: type.zPosition)
        }
    }
    
    func hide(_ type: OverlayType, animated: Bool = true) {
        guard let overlay = overlays[type] else { return }
        
        activeOverlays.remove(type)
        overlay.hide(animated: animated)
        
        if overlay.dimBackground {
            removeBackgroundDim()
        }
    }
    
    func toggle(_ type: OverlayType) {
        if activeOverlays.contains(type) {
            hide(type)
        } else {
            show(type)
        }
    }
    
    func hideAll(except exceptions: [OverlayType] = []) {
        for type in activeOverlays {
            if !exceptions.contains(type) {
                hide(type)
            }
        }
    }
    
    func isActive(_ type: OverlayType) -> Bool {
        return activeOverlays.contains(type)
    }
    
    func hasActiveModalOverlay() -> Bool {
        for type in activeOverlays {
            if let overlay = overlays[type], overlay.isModal {
                return true
            }
        }
        return false
    }
    
    func update(deltaTime: TimeInterval) {
        for type in activeOverlays {
            overlays[type]?.update(deltaTime: deltaTime)
        }
    }
    
    private func addBackgroundDim(below zPosition: CGFloat) {
        if overlayContainer.childNode(withName: "backgroundDim") == nil {
            let dim = SKSpriteNode(color: .black, size: scene?.size ?? .zero)
            dim.name = "backgroundDim"
            dim.position = CGPoint.zero  // Center in the container which is now centered
            dim.alpha = 0
            dim.zPosition = zPosition - 1
            overlayContainer.addChild(dim)
            
            dim.run(SKAction.fadeAlpha(to: 0.5, duration: 0.3))
        }
    }
    
    private func removeBackgroundDim() {
        if let dim = overlayContainer.childNode(withName: "backgroundDim") {
            dim.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
        }
    }
}

protocol UIOverlay: AnyObject {
    var layer: HUDManager.OverlayType { get }
    var isModal: Bool { get }
    var dimBackground: Bool { get }
    
    func show(animated: Bool)
    func hide(animated: Bool)
    func update(deltaTime: TimeInterval)
}

class BaseOverlay: SKNode, UIOverlay {
    let layer: HUDManager.OverlayType
    var isModal: Bool = false
    var dimBackground: Bool = false
    let overlaySize: CGSize
    weak var hudManager: HUDManager? {
        return (parent as? HUDContainer)?.hudManager
    }
    
    init(layer: HUDManager.OverlayType, size: CGSize) {
        self.layer = layer
        self.overlaySize = size
        super.init()
        // Enable touch handling for overlays
        isUserInteractionEnabled = true
        setupOverlay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupOverlay() {
    }
    
    func show(animated: Bool) {
        isHidden = false
        removeAllActions()
        
        if animated {
            alpha = 0
            setScale(0.9)
            run(SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ]))
        } else {
            alpha = 1
            setScale(1.0)
        }
    }
    
    func hide(animated: Bool) {
        removeAllActions()
        
        if animated {
            run(SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 0.9, duration: 0.3)
                ]),
                SKAction.hide()
            ]))
        } else {
            isHidden = true
        }
    }
    
    func update(deltaTime: TimeInterval) {
    }
    
    func containsTouch(at point: CGPoint) -> Bool {
        // Check if any child contains the touch
        for child in children {
            let childPoint = convert(point, to: child)
            if child.contains(childPoint) {
                return true
            }
        }
        return false
    }
    
    // Subclasses should override touchesBegan for handling touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Default implementation - subclasses override this
    }
}