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
            interaction.registerHotspot(hotspot)
        }
        
        // Animation (character animation component)
        register(.animation) { _, entity, _, _, _ in
            entity.add(CharacterAnimationComponent())
        }
        
        // Navigation zone (attach optional approach point info)
        register(.navigation) { _, entity, data, _, _ in
            let props = data.properties
            if let approach = props.cgPoint("approachPoint") {
                let radius = CGFloat(props.double("interactionRadius") ?? 40.0)
                let zone = NavigationZoneComponent(approachPoint: approach, interactionRadius: radius)
                entity.add(zone)
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

