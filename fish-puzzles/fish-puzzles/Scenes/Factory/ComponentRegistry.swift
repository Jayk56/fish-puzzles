//
//  ComponentRegistry.swift
//  fish-puzzles
//
//  Registry for building components/entities from scene definitions
//

import SpriteKit

final class ComponentRegistry {
    typealias Builder = (_ entityID: String, _ entity: Entity, _ data: ComponentData, _ scene: BaseGameScene, _ interaction: InteractionSystem) -> Void
    
    static let shared = ComponentRegistry()
    private var builders: [ComponentData.ComponentType: Builder] = [:]
    
    private init() {
        registerDefaults()
    }
    
    func register(_ type: ComponentData.ComponentType, builder: @escaping Builder) {
        builders[type] = builder
    }
    
    func build(_ type: ComponentData.ComponentType, entityID: String, entity: Entity, data: ComponentData, scene: BaseGameScene, interaction: InteractionSystem) {
        builders[type]?(entityID, entity, data, scene, interaction)
    }
    
    // MARK: - Default Builders
    private func registerDefaults() {
        // Sprite
        register(.sprite) { entityID, entity, data, scene, _ in
            let props = data.properties
            let imageName = props.string("imageName")
            let size = props.cgSize("size")
            
            let node: SKSpriteNode
            if let image = imageName {
                node = SKSpriteNode(imageNamed: image)
            } else {
                node = SKSpriteNode(color: .lightGray, size: size ?? CGSize(width: 60, height: 60))
            }
            if let s = size { node.size = s }
            node.name = entityID
            entity.node = node
            scene.addChild(node)
        }
        
        // Interaction (hotspot)
        register(.interaction) { entityID, entity, data, scene, interaction in
            let props = data.properties
            let typeString = props.string("type") ?? "item"
            let desc = props.string("description") ?? entityID
            let requiresItem = props.string("requiresItem")
            let areaSize = props.cgSize("areaSize") ?? CGSize(width: 80, height: 80)
            let offset = props.cgPoint("offset") ?? .zero
            
            guard let node = entity.node else { return }
            let center = node.position + offset
            let area = CGRect(x: center.x - areaSize.width/2, y: center.y - areaSize.height/2, width: areaSize.width, height: areaSize.height)
            
            let hotspot = Hotspot(
                id: entityID,
                type: HotspotType.from(typeString),
                area: area,
                description: desc
            )
            hotspot.requiresItem = requiresItem
            hotspot.node = node
            if let delegate = scene as? HotspotDelegate {
                hotspot.delegate = delegate
            }
            interaction.registerHotspot(hotspot)
        }
        
        // Animation (character animation component)
        register(.animation) { _, entity, _, _, _ in
            entity.add(CharacterAnimationComponent())
        }
        
        // Navigation zone (attach optional approach point info)
        register(.navigation) { _, entity, data, scene, _ in
            let props = data.properties
            var approach: CGPoint?
            // 1) Absolute or normalized approachPoint
            if var ap = props.cgPoint("approachPoint") {
                if (0...1).contains(ap.x) && (0...1).contains(ap.y) {
                    ap = scene.safePosition(normalizedX: ap.x, normalizedY: ap.y)
                }
                approach = ap
            }
            // 2) Anchor-based approach relative to node frame
            if approach == nil, let anchor = props.string("approachAnchor"), let node = entity.node {
                let frame = node.frame
                approach = anchorPoint(for: anchor, in: frame)
                // Optional offset (absolute pixels)
                if let offset = props.cgPoint("offset"), let base = approach {
                    approach = CGPoint(x: base.x + offset.x, y: base.y + offset.y)
                }
            }
            
            if let approach = approach {
                let radius = CGFloat(props.double("interactionRadius") ?? 40.0)
                let zone = NavigationZoneComponent(approachPoint: approach, interactionRadius: radius)
                entity.add(zone)

                // Debug marker for approach point
                #if DEBUG
                let marker = SKShapeNode(circleOfRadius: 5)
                marker.fillColor = .magenta
                marker.strokeColor = .clear
                marker.position = approach
                marker.zPosition = 2000
                marker.name = "nav_approach_\(entity.node?.name ?? "")"
                scene.addChild(marker)
                print("🧭 Navigation: approach for \(entity.node?.name ?? "?") at \(approach) (radius=\(radius))")
                #endif
            }
        }
    }
}

// MARK: - Helpers
private extension Dictionary where Key == String, Value == AnyCodable {
    func string(_ key: String) -> String? {
        (self[key]?.value as? String)
    }
    func double(_ key: String) -> Double? {
        if let d = self[key]?.value as? Double { return d }
        if let i = self[key]?.value as? Int { return Double(i) }
        return nil
    }
    func cgSize(_ key: String) -> CGSize? {
        if let dict = self[key]?.value as? [String: Any] {
            let w = (dict["width"] as? Double) ?? (dict["w"] as? Double) ?? 0
            let h = (dict["height"] as? Double) ?? (dict["h"] as? Double) ?? 0
            return CGSize(width: w, height: h)
        }
        if let arr = self[key]?.value as? [Double], arr.count >= 2 {
            return CGSize(width: arr[0], height: arr[1])
        }
        return nil
    }
    func cgPoint(_ key: String) -> CGPoint? {
        if let dict = self[key]?.value as? [String: Any] {
            let x = (dict["x"] as? Double) ?? 0
            let y = (dict["y"] as? Double) ?? 0
            return CGPoint(x: x, y: y)
        }
        if let arr = self[key]?.value as? [Double], arr.count >= 2 {
            return CGPoint(x: arr[0], y: arr[1])
        }
        return nil
    }
}

private extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

private func anchorPoint(for anchor: String, in frame: CGRect) -> CGPoint? {
    let a = anchor.replacingOccurrences(of: " ", with: "_").lowercased()
    let midX = (frame.minX + frame.maxX) / 2
    let midY = (frame.minY + frame.maxY) / 2
    switch a {
    case "top_left", "left_top": return CGPoint(x: frame.minX, y: frame.maxY)
    case "top_center", "center_top": return CGPoint(x: midX, y: frame.maxY)
    case "top_right", "right_top": return CGPoint(x: frame.maxX, y: frame.maxY)
    case "center_left", "left_center": return CGPoint(x: frame.minX, y: midY)
    case "center", "middle": return CGPoint(x: midX, y: midY)
    case "center_right", "right_center": return CGPoint(x: frame.maxX, y: midY)
    case "bottom_left", "left_bottom": return CGPoint(x: frame.minX, y: frame.minY)
    case "bottom_center", "center_bottom": return CGPoint(x: midX, y: frame.minY)
    case "bottom_right", "right_bottom": return CGPoint(x: frame.maxX, y: frame.minY)
    default: return nil
    }
}

private extension HotspotType {
    static func from(_ str: String) -> HotspotType {
        switch str.lowercased() {
        case "door": return .door
        case "character": return .character
        case "puzzle": return .puzzle
        case "navigation": return .navigation
        case "examine": return .examine
        default: return .item
        }
    }
}
