//
//  InteractionProtocols.swift
//  fish-puzzles
//
//  Protocols to decouple systems and enable dependency injection
//

import SpriteKit

protocol HotspotManaging: AnyObject {
    func register(_ hotspot: Hotspot)
    func unregister(_ hotspotId: String)
    func handleTouch(at point: CGPoint, with item: String?) -> Bool
}

protocol VisualFeedbackProviding: AnyObject {
    func showHotspotGlow(on node: SKNode, level: GlowLevel)
    func showInteractionFeedback(at point: CGPoint, type: InteractionType)
    func showSuccess(at point: CGPoint)
    func showValidTarget(node: SKNode)
    func clearAllEffects()
    func clearEffects(on node: SKNode)
}

protocol AudioPlaying: AnyObject {
    func playSFX(_ filename: String, volume: Float)
}

extension AudioPlaying {
    func playSFX(_ filename: String) { playSFX(filename, volume: 1.0) }
}

protocol HintProviding: AnyObject {
    func playerInteracted()
}

protocol InventoryManaging: AnyObject {
    var selectedItem: Item? { get }
    func selectItem(_ item: Item?)
    func useItem(_ item: Item, on target: Entity) -> UseResult
}

// MARK: - Concrete Conformances

extension HotspotManager: HotspotManaging {}

extension VisualFeedbackSystem: VisualFeedbackProviding {
    func clearEffects(on node: SKNode) {
        // Remove common effect nodes we create
        ["hotspotGlow", "dropHighlight", "targetIndicator"].forEach { name in
            if let effect = node.childNode(withName: name) {
                effect.removeAllActions()
                effect.removeFromParent()
            }
        }
    }
}

extension AudioManager: AudioPlaying {}

extension ProgressiveHintSystem: HintProviding {}

extension InventoryManager: InventoryManaging {}
