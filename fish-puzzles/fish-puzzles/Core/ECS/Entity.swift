//
//  Entity.swift
//  fish-puzzles
//
//  Entity-Component System base classes
//

import Foundation
import SpriteKit

class Entity {
    let id = UUID()
    private var components: [String: Component] = [:]
    weak var node: SKNode?
    
    func add<T: Component>(_ component: T) {
        let key = String(describing: type(of: component))
        components[key] = component
        component.entity = self
        component.didAddToEntity()
    }
    
    func get<T: Component>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return components[key] as? T
    }
    
    func remove<T: Component>(_ type: T.Type) {
        let key = String(describing: type)
        if let component = components.removeValue(forKey: key) {
            component.willRemoveFromEntity()
            component.entity = nil
        }
    }
    
    func update(deltaTime: TimeInterval) {
        components.values.forEach { $0.update(deltaTime: deltaTime) }
    }
}

class Component {
    weak var entity: Entity?
    
    func didAddToEntity() {
        // Override in subclasses
    }
    
    func willRemoveFromEntity() {
        // Override in subclasses
    }
    
    func update(deltaTime: TimeInterval) {
        // Override in subclasses
    }
}
