//
//  HotspotSystem.swift
//  fish-puzzles
//
//  Hotspot interaction zones for point-and-click gameplay
//

import Foundation
import SpriteKit

protocol HotspotDelegate: AnyObject {
    func hotspotDidActivate(_ hotspot: Hotspot)
    func hotspotDidDeactivate(_ hotspot: Hotspot)
    func hotspotDidTrigger(_ hotspot: Hotspot, with item: String?)
}

enum HotspotType {
    case item
    case door
    case character
    case puzzle
    case navigation
    case examine
}

class Hotspot {
    let id: String
    let type: HotspotType
    var area: CGRect
    var isActive: Bool = true
    var requiresItem: String?
    var description: String
    weak var delegate: HotspotDelegate?
    weak var node: SKNode?
    
    init(id: String, type: HotspotType, area: CGRect, description: String) {
        self.id = id
        self.type = type
        self.area = area
        self.description = description
    }
    
    func contains(point: CGPoint) -> Bool {
        return area.contains(point)
    }
    
    func activate() {
        guard !isActive else { return }
        isActive = true
        delegate?.hotspotDidActivate(self)
        updateVisuals(active: true)
    }
    
    func deactivate() {
        guard isActive else { return }
        isActive = false
        delegate?.hotspotDidDeactivate(self)
        updateVisuals(active: false)
    }
    
    func trigger(with item: String? = nil) {
        guard isActive else { return }
        
        if let requiredItem = requiresItem {
            if item == requiredItem {
                delegate?.hotspotDidTrigger(self, with: item)
            }
        } else {
            delegate?.hotspotDidTrigger(self, with: item)
        }
    }
    
    private func updateVisuals(active: Bool) {
        node?.alpha = active ? 1.0 : 0.5
    }
}

class HotspotManager: HotspotDelegate {
    static let shared = HotspotManager()
    
    private var hotspots: [String: Hotspot] = [:]
    private var activeHotspot: Hotspot?
    private var debugMode: Bool = false
    
    private init() {}
    
    func register(_ hotspot: Hotspot) {
        hotspots[hotspot.id] = hotspot
        hotspot.delegate = self
    }
    
    func unregister(_ hotspotId: String) {
        hotspots.removeValue(forKey: hotspotId)
    }
    
    func getHotspot(at point: CGPoint) -> Hotspot? {
        for hotspot in hotspots.values {
            if hotspot.isActive && hotspot.contains(point: point) {
                return hotspot
            }
        }
        return nil
    }
    
    func handleTouch(at point: CGPoint, with item: String? = nil) -> Bool {
        if let hotspot = getHotspot(at: point) {
            activeHotspot = hotspot
            hotspot.trigger(with: item)
            return true
        }
        activeHotspot = nil
        return false
    }
    
    func setDebugMode(_ enabled: Bool) {
        debugMode = enabled
    }
    
    func createDebugNodes(in scene: SKScene) {
        guard debugMode else { return }
        
        for hotspot in hotspots.values {
            let debugNode = SKShapeNode(rect: hotspot.area)
            debugNode.strokeColor = .green
            debugNode.lineWidth = 2
            debugNode.fillColor = SKColor.green.withAlphaComponent(0.2)
            debugNode.zPosition = 1000
            debugNode.name = "debug_hotspot_\(hotspot.id)"
            scene.addChild(debugNode)
        }
    }
    
    func clearDebugNodes(from scene: SKScene) {
        scene.enumerateChildNodes(withName: "debug_hotspot_*") { node, _ in
            node.removeFromParent()
        }
    }
    
    // HotspotDelegate
    func hotspotDidActivate(_ hotspot: Hotspot) {
        print("Hotspot activated: \(hotspot.id)")
    }
    
    func hotspotDidDeactivate(_ hotspot: Hotspot) {
        print("Hotspot deactivated: \(hotspot.id)")
    }
    
    func hotspotDidTrigger(_ hotspot: Hotspot, with item: String?) {
        print("Hotspot triggered: \(hotspot.id) with item: \(item ?? "none")")
    }
}

class HotspotComponent: Component {
    var hotspot: Hotspot?
    
    init(hotspot: Hotspot) {
        self.hotspot = hotspot
        super.init()
    }
    
    override func didAddToEntity() {
        guard let hotspot = hotspot else { return }
        HotspotManager.shared.register(hotspot)
        hotspot.node = entity?.node
    }
    
    override func willRemoveFromEntity() {
        guard let hotspot = hotspot else { return }
        HotspotManager.shared.unregister(hotspot.id)
    }
}