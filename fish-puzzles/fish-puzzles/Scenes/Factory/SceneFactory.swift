//
//  SceneFactory.swift
//  fish-puzzles
//
//  Builds scene content from SceneDefinition using ComponentRegistry
//

import SpriteKit

final class SceneFactory {
    static func build(from definition: SceneDefinition, into scene: BaseGameScene, interaction: InteractionSystem) -> [Entity] {
        var built: [Entity] = []
        for entityDef in definition.entities {
            let entity = Entity()
            // Build in phases so builders that depend on node/frame run after position is known
            let components = entityDef.components
            // 1) Sprite first (creates node)
            if let spriteData = components["sprite"] {
                ComponentRegistry.shared.build(spriteData.type, entityID: entityDef.id, entity: entity, data: spriteData, scene: scene, interaction: interaction)
            }
            // 2) Ensure node has a name and position before other builders
            if let node = entity.node {
                node.name = node.name ?? entityDef.id
                let x = entityDef.position.x, y = entityDef.position.y
                if (0...1).contains(x) && (0...1).contains(y) {
                    node.position = scene.safePosition(normalizedX: x, normalizedY: y)
                } else {
                    node.position = CGPoint(x: x, y: y)
                }
            }
            // 3) Other components: animation, interaction, navigation (these can rely on node position)
            for (key, data) in components where key != "sprite" {
                ComponentRegistry.shared.build(data.type, entityID: entityDef.id, entity: entity, data: data, scene: scene, interaction: interaction)
            }
            built.append(entity)
            scene.entities.append(entity)
        }
        return built
    }
}
