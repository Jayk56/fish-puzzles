//
//  ProgressiveHintSystem.swift
//  fish-puzzles
//
//  Provides progressive hints when players are stuck
//

import Foundation
import SpriteKit

class ProgressiveHintSystem {
    static let shared = ProgressiveHintSystem()
    
    private var idleTimer: Timer?
    private var currentIdleTime: TimeInterval = 0
    private var currentHintLevel: HintLevel = .none
    private var hintCooldown: TimeInterval = 0
    private var lastInteractionTime: Date = Date()
    
    var currentPuzzle: Puzzle?  // Puzzle is a struct, can't be weak
    weak var scene: SKScene?
    
    private let hintThresholds: [HintLevel: TimeInterval] = [
        .none: 0,
        .environmental: 15,
        .interface: 30,
        .directional: 45,
        .explicit: 60
    ]
    
    private init() {
        startIdleTracking()
    }
    
    func startIdleTracking() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateIdleTime()
        }
    }
    
    func stopIdleTracking() {
        idleTimer?.invalidate()
        idleTimer = nil
    }
    
    func resetIdleTime() {
        currentIdleTime = 0
        currentHintLevel = .none
        lastInteractionTime = Date()
        hintCooldown = 0
        
        VisualFeedbackSystem.shared.clearAllEffects()
    }
    
    func playerInteracted() {
        resetIdleTime()
    }
    
    func setPuzzle(_ puzzle: Puzzle) {
        currentPuzzle = puzzle
        resetIdleTime()
    }
    
    private func updateIdleTime() {
        let timeSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
        currentIdleTime = timeSinceLastInteraction
        
        if hintCooldown > 0 {
            hintCooldown -= 1
            return
        }
        
        let appropriateLevel = getHintLevel(for: currentIdleTime)
        if appropriateLevel != currentHintLevel && appropriateLevel != .none {
            showHint(level: appropriateLevel)
            currentHintLevel = appropriateLevel
        }
    }
    
    private func getHintLevel(for idleTime: TimeInterval) -> HintLevel {
        if idleTime >= hintThresholds[.explicit]! {
            return .explicit
        } else if idleTime >= hintThresholds[.directional]! {
            return .directional
        } else if idleTime >= hintThresholds[.interface]! {
            return .interface
        } else if idleTime >= hintThresholds[.environmental]! {
            return .environmental
        }
        return .none
    }
    
    private func showHint(level: HintLevel) {
        guard let puzzle = currentPuzzle else { return }
        
        switch level {
        case .none:
            break
            
        case .environmental:
            showEnvironmentalHint(for: puzzle)
            
        case .interface:
            showInterfaceHint(for: puzzle)
            
        case .directional:
            showDirectionalHint(for: puzzle)
            
        case .explicit:
            showExplicitHint(for: puzzle)
        }
        
        hintCooldown = 10
        GameEngine.shared.incrementHintsUsed()
    }
    
    private func showEnvironmentalHint(for puzzle: Puzzle) {
        if let targetNode = puzzle.solutionObject?.node {
            VisualFeedbackSystem.shared.showHotspotGlow(
                on: targetNode,
                level: .subtle
            )
        }
        
        showHintMessage("Something in this area might be useful...", level: .environmental)
    }
    
    private func showInterfaceHint(for puzzle: Puzzle) {
        if let requiredItem = puzzle.requiredItem {
            highlightInventoryItem(requiredItem)
        }
        
        if let targetNode = puzzle.solutionObject?.node {
            VisualFeedbackSystem.shared.showHotspotGlow(
                on: targetNode,
                level: .moderate
            )
        }
        
        showHintMessage("Check your inventory for something helpful!", level: .interface)
    }
    
    private func showDirectionalHint(for puzzle: Puzzle) {
        if let path = puzzle.solutionPath {
            showBreadcrumbs(along: path)
        }
        
        if let targetNode = puzzle.solutionObject?.node {
            VisualFeedbackSystem.shared.showHotspotGlow(
                on: targetNode,
                level: .strong
            )
        }
        
        let hint = puzzle.hint ?? "Follow the glowing path!"
        showHintMessage(hint, level: .directional)
    }
    
    private func showExplicitHint(for puzzle: Puzzle) {
        if let solution = puzzle.explicitSolution {
            showGhostPlayer(performing: solution)
        }
        
        if let targetNode = puzzle.solutionObject?.node {
            VisualFeedbackSystem.shared.showHotspotGlow(
                on: targetNode,
                level: .urgent
            )
        }
        
        let hint = puzzle.explicitHint ?? "Use \(puzzle.requiredItem?.name ?? "the item") on the glowing object!"
        showHintMessage(hint, level: .explicit)
    }
    
    private func highlightInventoryItem(_ item: Item) {
        if let inventoryBar = (scene as? BaseGameScene)?.hudManager?.inventoryBar {
            inventoryBar.visibleSlots.forEach { slot in
                if slot.item?.id == item.id {
                    slot.showValidDropTarget()
                }
            }
        }
    }
    
    private func showBreadcrumbs(along path: [CGPoint]) {
        guard let scene = scene else { return }
        
        for (index, point) in path.enumerated() {
            let breadcrumb = createBreadcrumb(index: index)
            breadcrumb.position = point
            breadcrumb.zPosition = 100
            scene.addChild(breadcrumb)
            
            breadcrumb.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(index) * 0.2),
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.wait(forDuration: 5.0),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    private func createBreadcrumb(index: Int) -> SKNode {
        let arrow = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 10))
        path.addLine(to: CGPoint(x: -5, y: 0))
        path.addLine(to: CGPoint(x: 5, y: 0))
        path.closeSubpath()
        
        arrow.path = path
        arrow.fillColor = .systemYellow
        arrow.alpha = 0
        
        arrow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.5),
            SKAction.fadeAlpha(to: 0.3, duration: 0.5)
        ])))
        
        return arrow
    }
    
    private func showGhostPlayer(performing solution: PuzzleSolution) {
        guard let scene = scene else { return }
        
        let ghost = createGhostPlayer()
        ghost.position = solution.startPosition
        ghost.zPosition = 500
        scene.addChild(ghost)
        
        var actions: [SKAction] = []
        
        for step in solution.steps {
            switch step {
            case .moveTo(let position):
                actions.append(SKAction.move(to: position, duration: 1.0))
                
            case .pickUp(let item):
                actions.append(SKAction.run {
                    self.showItemPickupGhost(item: item, at: ghost.position)
                })
                actions.append(SKAction.wait(forDuration: 0.5))
                
            case .useItem(let item, let target):
                actions.append(SKAction.run {
                    self.showItemUseGhost(item: item, target: target, at: ghost.position)
                })
                actions.append(SKAction.wait(forDuration: 0.5))
            }
        }
        
        actions.append(SKAction.fadeOut(withDuration: 0.5))
        actions.append(SKAction.removeFromParent())
        
        ghost.run(SKAction.sequence(actions))
    }
    
    private func createGhostPlayer() -> SKNode {
        let ghost = SKShapeNode(circleOfRadius: 20)
        ghost.fillColor = .systemBlue
        ghost.alpha = 0.5
        ghost.strokeColor = .white
        ghost.lineWidth = 2
        ghost.glowWidth = 5
        
        ghost.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 0.5, duration: 0.5)
        ])))
        
        return ghost
    }
    
    private func showItemPickupGhost(item: Item, at position: CGPoint) {
        guard let scene = scene else { return }
        
        let itemGhost = SKSpriteNode(imageNamed: item.imageName)
        itemGhost.size = CGSize(width: 40, height: 40)
        itemGhost.position = position
        itemGhost.alpha = 0.5
        itemGhost.zPosition = 501
        
        scene.addChild(itemGhost)
        
        itemGhost.run(SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.3),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 50, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    private func showItemUseGhost(item: Item, target: Entity, at position: CGPoint) {
        guard let scene = scene else { return }
        
        let itemGhost = SKSpriteNode(imageNamed: item.imageName)
        itemGhost.size = CGSize(width: 40, height: 40)
        itemGhost.position = position
        itemGhost.alpha = 0.5
        itemGhost.zPosition = 501
        
        scene.addChild(itemGhost)
        
        let targetPos = target.node?.position ?? .zero
        
        itemGhost.run(SKAction.sequence([
            SKAction.move(to: targetPos, duration: 0.5),
            SKAction.scale(to: 0.1, duration: 0.2),
            SKAction.removeFromParent()
        ]))
    }
    
    private func showHintMessage(_ message: String, level: HintLevel) {
        guard let scene = scene else { return }
        
        let hintBubble = createHintBubble(message: message, level: level)
        hintBubble.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 100)
        hintBubble.zPosition = 1000
        
        scene.addChild(hintBubble)
        
        hintBubble.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ]),
            SKAction.wait(forDuration: 5.0),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.scale(to: 0.8, duration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))
        
        AudioManager.shared.playSFX("hint_appear")
    }
    
    private func createHintBubble(message: String, level: HintLevel) -> SKNode {
        let container = SKNode()
        container.setScale(0.8)
        container.alpha = 0
        
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: 80), cornerRadius: 15)
        background.fillColor = level.backgroundColor
        background.strokeColor = level.borderColor
        background.lineWidth = 2
        container.addChild(background)
        
        let icon = SKLabelNode(text: "💡")
        icon.fontSize = 24
        icon.position = CGPoint(x: -120, y: -8)
        container.addChild(icon)
        
        let label = SKLabelNode(text: message)
        label.fontSize = 16
        label.fontName = "AvenirNext-Regular"
        label.preferredMaxLayoutWidth = 240
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 10, y: 0)
        container.addChild(label)
        
        return container
    }
}

enum HintLevel: Int {
    case none = 0
    case environmental = 1
    case interface = 2
    case directional = 3
    case explicit = 4
    
    var backgroundColor: UIColor {
        switch self {
        case .none: return .clear
        case .environmental: return UIColor(white: 0.2, alpha: 0.9)
        case .interface: return UIColor(white: 0.3, alpha: 0.9)
        case .directional: return UIColor.systemBlue.withAlphaComponent(0.3)
        case .explicit: return UIColor.systemOrange.withAlphaComponent(0.3)
        }
    }
    
    var borderColor: UIColor {
        switch self {
        case .none: return .clear
        case .environmental: return .systemGray
        case .interface: return .systemYellow
        case .directional: return .systemBlue
        case .explicit: return .systemOrange
        }
    }
}

// Puzzle struct removed - using the Puzzle class from PuzzleSystem.swift instead

struct PuzzleSolution {
    let startPosition: CGPoint
    let steps: [SolutionStep]
}

enum SolutionStep {
    case moveTo(CGPoint)
    case pickUp(Item)
    case useItem(Item, Entity)
}