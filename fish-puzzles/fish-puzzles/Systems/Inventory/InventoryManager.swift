//
//  InventoryManager.swift
//  fish-puzzles
//
//  Manages game inventory and item interactions
//

import Foundation
import SpriteKit

class InventoryManager {
    static let shared = InventoryManager()
    
    private(set) var items: [Item] = []
    private(set) var selectedItem: Item?
    
    var visibleSlots: [Item] {
        return Array(items.prefix(PersistentInventoryBar.maxVisibleSlots))
    }
    
    var overflowItems: [Item] {
        return Array(items.dropFirst(PersistentInventoryBar.maxVisibleSlots))
    }
    
    weak var persistentBar: PersistentInventoryBar?
    weak var interactionEngine: ItemInteractionEngine?
    
    var onInventoryChanged: (([Item]) -> Void)?
    var onItemSelected: ((Item?) -> Void)?
    
    private init() {}
    
    func addItem(_ item: Item) {
        items.append(item)
        persistentBar?.addItem(item)
        onInventoryChanged?(items)
        
        AudioManager.shared.playSFX("item_pickup")
    }
    
    func removeItem(_ item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            persistentBar?.removeItem(item)
            
            if selectedItem?.id == item.id {
                selectItem(nil)
            }
            
            onInventoryChanged?(items)
        }
    }
    
    func hasItem(_ item: Item) -> Bool {
        return items.contains(where: { $0.id == item.id })
    }
    
    func hasItem(withId id: String) -> Bool {
        return items.contains(where: { $0.id == id })
    }
    
    func selectItem(_ item: Item?) {
        selectedItem = item
        persistentBar?.selectItem(item)
        onItemSelected?(item)
    }
    
    func useItem(_ item: Item, on target: Entity) -> UseResult {
        guard let engine = interactionEngine else {
            return .invalid(reason: "No interaction engine")
        }
        
        return engine.attemptUse(item: item, on: target)
    }
    
    func combineItems(_ item1: Item, _ item2: Item) -> Item? {
        guard let engine = interactionEngine else { return nil }
        
        if let result = engine.attemptCombination(item1: item1, item2: item2) {
            removeItem(item1)
            removeItem(item2)
            addItem(result)
            
            AudioManager.shared.playSFX("item_combine_success")
            return result
        } else {
            AudioManager.shared.playSFX("item_combine_fail")
            return nil
        }
    }
    
    func canCombineItems(_ item1: Item, _ item2: Item) -> Bool {
        return interactionEngine?.canCombineItems(item1, item2) ?? false
    }
    
    func clearInventory() {
        items.removeAll()
        selectedItem = nil
        persistentBar?.updateInventory(items: [])
        onInventoryChanged?([])
    }
    
    func saveState() -> InventoryState {
        return InventoryState(
            items: items,
            selectedItemId: selectedItem?.id
        )
    }
    
    func loadState(_ state: InventoryState) {
        items = state.items
        persistentBar?.updateInventory(items: items)
        
        if let selectedId = state.selectedItemId,
           let item = items.first(where: { $0.id == selectedId }) {
            selectItem(item)
        }
        
        onInventoryChanged?(items)
    }
}

struct InventoryState: Codable {
    let items: [Item]
    let selectedItemId: String?
}

enum UseResult {
    case success(effects: [Effect])
    case partial(hint: String, effects: [Effect])
    case invalid(reason: String)
    case funny(message: String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

struct Effect {
    enum EffectType {
        case playSound(String)
        case playAnimation(String)
        case showParticles(String)
        case changeSprite(String)
        case unlock(String)
        case triggerDialogue(String)
    }
    
    let type: EffectType
    let target: Entity?
    let delay: TimeInterval
}