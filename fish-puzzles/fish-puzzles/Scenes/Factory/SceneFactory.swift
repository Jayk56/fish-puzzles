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
            // Build components
            for (_, componentData) in entityDef.components {
                ComponentRegistry.shared.build(componentData.type, entityID: entityDef.id, entity: entity, data: componentData, scene: scene, interaction: interaction)
            }
            // Ensure node has a name and position
            if let node = entity.node {
                node.name = node.name ?? entityDef.id
                node.position = CGPoint(x: entityDef.position.x, y: entityDef.position.y)
            }
            built.append(entity)
            scene.entities.append(entity)
        }
        return built
    }
}

