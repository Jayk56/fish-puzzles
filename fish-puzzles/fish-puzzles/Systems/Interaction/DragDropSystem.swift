//
//  DragDropSystem.swift
//  fish-puzzles
//
//  Handles drag and drop interactions for inventory items
//

import SpriteKit

class DragDropSystem {
    static let shared = DragDropSystem()
    
    var draggedItem: Item?
    private var draggedNode: SKNode?
    private var originalPosition: CGPoint = .zero
    private var dragThreshold: CGFloat = 15
    private var isDragging = false
    
    weak var scene: SKScene?
    weak var inventoryBar: PersistentInventoryBar?
    
    var onDragStart: ((Item, CGPoint) -> Void)?
    var onDragMove: ((Item, CGPoint) -> Void)?
    var onDragEnd: ((Item, CGPoint, SKNode?) -> Void)?
    
    private init() {}
    
    func handleTouchBegan(_ touch: UITouch, in scene: SKScene) -> Bool {
        let location = touch.location(in: scene)
        
        if let inventoryBar = inventoryBar,
           let touchedNode = scene.atPoint(location) as? InventorySlot,
           let item = touchedNode.item {
            
            prepareDrag(item: item, from: touchedNode, at: location)
            return true
        }
        
        return false
    }
    
    func handleTouchMoved(_ touch: UITouch, in scene: SKScene) {
        guard draggedItem != nil else { return }
        
        let location = touch.location(in: scene)
        let distance = hypot(
            location.x - originalPosition.x,
            location.y - originalPosition.y
        )
        
        if !isDragging && distance > dragThreshold {
            startDrag(at: location)
        }
        
        if isDragging {
            updateDrag(at: location)
        }
    }
    
    func handleTouchEnded(_ touch: UITouch, in scene: SKScene) {
        guard let item = draggedItem else { return }
        
        let location = touch.location(in: scene)
        
        if isDragging {
            endDrag(at: location)
        } else {
            cancelDrag()
        }
    }
    
    private func prepareDrag(item: Item, from node: SKNode, at location: CGPoint) {
        draggedItem = item
        originalPosition = location
        
        let dragVisual = createDragVisual(for: item)
        dragVisual.position = location
        dragVisual.zPosition = 2000
        scene?.addChild(dragVisual)
        draggedNode = dragVisual
    }
    
    private func startDrag(at location: CGPoint) {
        guard let item = draggedItem else { return }
        
        isDragging = true
        
        draggedNode?.run(SKAction.group([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.fadeAlpha(to: 0.8, duration: 0.1)
        ]))
        
        inventoryBar?.highlightValidTarget(for: item)
        highlightValidDropTargets(for: item)
        
        onDragStart?(item, location)
        
        AudioManager.shared.playSFX("drag_start")
    }
    
    private func updateDrag(at location: CGPoint) {
        guard let item = draggedItem else { return }
        
        draggedNode?.position = location
        
        if let targetNode = findDropTarget(at: location) {
            if canDropItem(item, on: targetNode) {
                showValidDropFeedback(on: targetNode)
            } else {
                showInvalidDropFeedback(on: targetNode)
            }
        } else {
            clearDropFeedback()
        }
        
        onDragMove?(item, location)
    }
    
    private func endDrag(at location: CGPoint) {
        guard let item = draggedItem else { return }
        
        if let targetNode = findDropTarget(at: location) {
            if canDropItem(item, on: targetNode) {
                performDrop(item: item, on: targetNode)
            } else {
                animateReturnToOrigin()
            }
        } else {
            animateReturnToOrigin()
        }
        
        clearDropFeedback()
        inventoryBar?.clearHighlights()
        
        onDragEnd?(item, location, findDropTarget(at: location))
        
        cleanup()
    }
    
    private func cancelDrag() {
        draggedNode?.removeFromParent()
        cleanup()
    }
    
    private func cleanup() {
        draggedItem = nil
        draggedNode = nil
        isDragging = false
        originalPosition = .zero
    }
    
    private func createDragVisual(for item: Item) -> SKNode {
        let container = SKNode()
        
        let sprite = SKSpriteNode(imageNamed: item.imageName)
        sprite.size = CGSize(width: 70, height: 70)
        container.addChild(sprite)
        
        let shadow = SKShapeNode(circleOfRadius: 35)
        shadow.fillColor = .black
        shadow.alpha = 0.3
        shadow.position = CGPoint(x: 5, y: -5)
        shadow.zPosition = -1
        container.addChild(shadow)
        
        let wiggle = SKAction.sequence([
            SKAction.rotate(byAngle: 0.05, duration: 0.1),
            SKAction.rotate(byAngle: -0.1, duration: 0.2),
            SKAction.rotate(byAngle: 0.05, duration: 0.1)
        ])
        container.run(SKAction.repeatForever(wiggle))
        
        return container
    }
    
    private func findDropTarget(at location: CGPoint) -> SKNode? {
        guard let scene = scene else { return nil }
        let nodes = scene.nodes(at: location)
        
        // Prefer inventory slots first
        if let slot = nodes.first(where: { $0 is InventorySlot }) {
            return slot
        }
        
        // Otherwise, any node that belongs to an entity
        for node in nodes {
            if resolveEntity(from: node) != nil {
                return node
            }
        }
        return nil
    }

    private func resolveEntity(from node: SKNode) -> Entity? {
        guard let gameScene = scene as? BaseGameScene else { return nil }
        var current: SKNode? = node
        while let n = current {
            if let entity = gameScene.entities.first(where: { $0.node === n }) {
                return entity
            }
            current = n.parent
        }
        return nil
    }
    
    private func canDropItem(_ item: Item, on target: SKNode) -> Bool {
        if let slot = target as? InventorySlot, let slotItem = slot.item {
            return InventoryManager.shared.canCombineItems(item, slotItem)
        }
        if let entity = resolveEntity(from: target) {
            return ItemInteractionEngine.shared.canUseItem(item, on: entity)
        }
        return false
    }
    
    private func performDrop(item: Item, on target: SKNode) {
        if let slot = target as? InventorySlot, let slotItem = slot.item {
            animateCombination(item: item, with: slotItem, at: slot.position) {
                _ = InventoryManager.shared.combineItems(item, slotItem)
            }
            return
        }
        if let entity = resolveEntity(from: target) {
            animateUse(item: item, on: entity) {
                let result = InventoryManager.shared.useItem(item, on: entity)
                if result.isSuccess {
                    InventoryManager.shared.removeItem(item)
                }
            }
        }
    }
    
    private func animateCombination(item: Item, with otherItem: Item, at position: CGPoint, completion: @escaping () -> Void) {
        guard let dragNode = draggedNode else { return }
        
        let moveAction = SKAction.move(to: position, duration: 0.2)
        let scaleAction = SKAction.scale(to: 0.1, duration: 0.2)
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 0.2)
        
        dragNode.run(SKAction.group([moveAction, scaleAction, rotateAction])) {
            dragNode.removeFromParent()
            self.createCombinationEffect(at: position)
            completion()
        }
    }
    
    private func animateUse(item: Item, on entity: Entity, completion: @escaping () -> Void) {
        guard let dragNode = draggedNode else { return }
        
        let targetPos = entity.node?.position ?? .zero
        
        dragNode.run(SKAction.sequence([
            SKAction.move(to: targetPos, duration: 0.2),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.1, duration: 0.2)
            ])
        ])) {
            dragNode.removeFromParent()
            completion()
        }
    }
    
    private func animateReturnToOrigin() {
        guard let dragNode = draggedNode else { return }
        
        dragNode.run(SKAction.sequence([
            SKAction.move(to: originalPosition, duration: 0.3),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.5, duration: 0.2)
            ])
        ])) {
            dragNode.removeFromParent()
        }
        
        AudioManager.shared.playSFX("drag_cancel")
    }
    
    private func highlightValidDropTargets(for item: Item) {
        guard let gameScene = scene as? BaseGameScene else { return }
        gameScene.entities.forEach { entity in
            if ItemInteractionEngine.shared.canUseItem(item, on: entity), let node = entity.node {
                self.addHighlight(to: node, color: .systemGreen)
            }
        }
    }
    
    private func showValidDropFeedback(on node: SKNode) {
        addHighlight(to: node, color: .systemGreen, animated: true)
    }
    
    private func showInvalidDropFeedback(on node: SKNode) {
        addHighlight(to: node, color: .systemRed, animated: false)
        
        node.run(SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.1),
            SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        ]))
    }
    
    private func addHighlight(to node: SKNode, color: UIColor, animated: Bool = false) {
        let highlight = node.childNode(withName: "dropHighlight") as? SKShapeNode
            ?? createHighlight(for: node, color: color)
        
        if animated {
            highlight.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.3),
                SKAction.fadeAlpha(to: 0.8, duration: 0.3)
            ])))
        }
    }
    
    private func createHighlight(for node: SKNode, color: UIColor) -> SKShapeNode {
        let size = node.frame.size
        let highlight = SKShapeNode(rectOf: CGSize(
            width: size.width + 20,
            height: size.height + 20
        ), cornerRadius: 10)
        
        highlight.name = "dropHighlight"
        highlight.strokeColor = color
        highlight.lineWidth = 3
        highlight.glowWidth = 5
        highlight.fillColor = .clear
        highlight.zPosition = -1
        
        node.addChild(highlight)
        return highlight
    }
    
    private func clearDropFeedback() {
        scene?.enumerateChildNodes(withName: "//dropHighlight") { node, _ in
            node.removeAllActions()
            node.removeFromParent()
        }
    }
    
    private func createCombinationEffect(at position: CGPoint) {
        guard let scene = scene else { return }
        
        let emitter = SKEmitterNode()
        emitter.particleTexture = AssetManager.shared.texture(named: "spark")
        emitter.particleBirthRate = 200
        emitter.particleLifetime = 0.5
        emitter.particleScale = 0.3
        emitter.particleScaleSpeed = -0.6
        emitter.particleSpeed = 100
        emitter.emissionAngleRange = .pi * 2
        emitter.particleColor = .systemCyan
        emitter.position = position
        emitter.zPosition = 1500
        
        scene.addChild(emitter)
        
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        
        AudioManager.shared.playSFX("combine_success")
    }
}
