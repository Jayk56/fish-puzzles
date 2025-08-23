//
//  ItemInteractionEngine.swift
//  fish-puzzles
//
//  Handles item usage rules and combinations
//

import Foundation
import SpriteKit

class ItemInteractionEngine {
    static let shared = ItemInteractionEngine()
    
    private var interactionRules: [InteractionRule] = []
    private var combinationRecipes: [CombinationRecipe] = []
    private var funnyResponses: [String: String] = [:]
    
    private init() {
        loadInteractionRules()
        loadCombinationRecipes()
        loadFunnyResponses()
    }
    
    func attemptUse(item: Item, on target: Entity) -> UseResult {
        if let rule = findRule(item: item, target: target) {
            if checkConditions(rule.conditions) {
                return executeInteraction(rule)
            } else {
                return .partial(
                    hint: "You need something else first...",
                    effects: []
                )
            }
        }
        
        if let funnyResponse = getFunnyResponse(item: item, target: target) {
            return .funny(message: funnyResponse)
        }
        
        if isCloseToCorrect(item: item, target: target) {
            return .partial(
                hint: "That's the right idea, but not quite right...",
                effects: []
            )
        }
        
        return .invalid(reason: "That doesn't work here.")
    }
    
    func attemptCombination(item1: Item, item2: Item) -> Item? {
        if let recipe = findRecipe(item1: item1, item2: item2) {
            return createItem(from: recipe)
        }
        return nil
    }
    
    func canCombineItems(_ item1: Item, _ item2: Item) -> Bool {
        return findRecipe(item1: item1, item2: item2) != nil
    }
    
    func canUseItem(_ item: Item, on target: Entity) -> Bool {
        return findRule(item: item, target: target) != nil
    }
    
    func getHint(for item: Item) -> String? {
        if let rule = interactionRules.first(where: { $0.itemID == item.id }) {
            return rule.hint
        }
        return nil
    }
    
    private func findRule(item: Item, target: Entity) -> InteractionRule? {
        return interactionRules.first { rule in
            rule.itemID == item.id && rule.targetID == target.id.uuidString
        }
    }
    
    private func findRecipe(item1: Item, item2: Item) -> CombinationRecipe? {
        return combinationRecipes.first { recipe in
            (recipe.inputs.contains(item1.id) && recipe.inputs.contains(item2.id)) ||
            (recipe.inputs.contains(item2.id) && recipe.inputs.contains(item1.id))
        }
    }
    
    private func checkConditions(_ conditions: [InteractionCondition]) -> Bool {
        for condition in conditions {
            switch condition {
            case .hasItem(let itemId):
                if !InventoryManager.shared.hasItem(withId: itemId) {
                    return false
                }
            case .locationIs(let sceneId):
                if GameState.shared.currentSceneID != sceneId {
                    return false
                }
            case .puzzleSolved(let puzzleId):
                if !GameState.shared.puzzlesSolved.contains(puzzleId) {
                    return false
                }
            case .characterMet(let characterId):
                if !GameState.shared.charactersmet.contains(characterId) {
                    return false
                }
            }
        }
        return true
    }
    
    private func executeInteraction(_ rule: InteractionRule) -> UseResult {
        var effects: [Effect] = []
        
        switch rule.action {
        case .unlock:
            effects.append(Effect(
                type: .unlock(rule.targetID),
                target: nil,
                delay: 0
            ))
            effects.append(Effect(
                type: .playSound("unlock"),
                target: nil,
                delay: 0
            ))
            
        case .transform:
            effects.append(Effect(
                type: .changeSprite(rule.resultSprite ?? ""),
                target: nil,
                delay: 0
            ))
            effects.append(Effect(
                type: .showParticles("transform"),
                target: nil,
                delay: 0
            ))
            
        case .trigger:
            effects.append(Effect(
                type: .triggerDialogue(rule.dialogueID ?? ""),
                target: nil,
                delay: 0
            ))
            
        case .collect:
            break
        }
        
        return .success(effects: effects)
    }
    
    private func isCloseToCorrect(item: Item, target: Entity) -> Bool {
        if item.id.contains("key") && target.type == .door {
            return true
        }
        
        if item.id.contains("tool") && target.requiresTool {
            return true
        }
        
        return false
    }
    
    private func getFunnyResponse(item: Item, target: Entity) -> String? {
        let key = "\(item.id)+\(target.id)"
        return funnyResponses[key]
    }
    
    private func createItem(from recipe: CombinationRecipe) -> Item? {
        return Item(
            id: recipe.outputID,
            name: recipe.outputName,
            displayName: recipe.outputDisplayName,
            imageName: recipe.outputImage,
            description: recipe.outputDescription
        )
    }
    
    private func loadInteractionRules() {
        interactionRules = [
            InteractionRule(
                itemID: "key_blue",
                targetID: "door_blue",
                action: .unlock,
                conditions: [],
                hint: "This key looks like it fits a blue door."
            ),
            InteractionRule(
                itemID: "fishing_rod",
                targetID: "pond",
                action: .trigger,
                conditions: [],
                hint: "Perfect for fishing!",
                dialogueID: "catch_fish"
            )
        ]
    }
    
    private func loadCombinationRecipes() {
        combinationRecipes = [
            CombinationRecipe(
                id: "fishing_rod_recipe",
                ingredients: Set(["stick", "string"]),
                result: "fishing_rod",
                description: "A simple fishing rod",
                inputs: ["stick", "string"],
                outputID: "fishing_rod",
                outputName: "Fishing Rod",
                outputDisplayName: "Fishing Rod",
                outputImage: "fishing_rod",
                outputDescription: "A simple fishing rod",
                animation: .bind
            ),
            CombinationRecipe(
                id: "green_paint_recipe",
                ingredients: Set(["blue_paint", "yellow_paint"]),
                result: "green_paint",
                description: "Mixed green paint",
                inputs: ["blue_paint", "yellow_paint"],
                outputID: "green_paint",
                outputName: "Green Paint",
                outputDisplayName: "Green Paint",
                outputImage: "green_paint",
                outputDescription: "Mixed green paint",
                animation: .swirl
            )
        ]
    }
    
    private func loadFunnyResponses() {
        funnyResponses = [
            "fish+bicycle": "The fish doesn't know how to ride!",
            "key+soup": "The key would just get soggy!",
            "hat+sandwich": "That's not a lunch box!",
            "shoe+pond": "The fish don't need shoes!"
        ]
    }
}

struct InteractionRule {
    let itemID: String
    let targetID: String
    let action: InteractionAction
    let conditions: [InteractionCondition]
    let hint: String?
    let resultSprite: String?
    let dialogueID: String?
    
    init(itemID: String, targetID: String, action: InteractionAction,
         conditions: [InteractionCondition] = [], hint: String? = nil,
         resultSprite: String? = nil, dialogueID: String? = nil) {
        self.itemID = itemID
        self.targetID = targetID
        self.action = action
        self.conditions = conditions
        self.hint = hint
        self.resultSprite = resultSprite
        self.dialogueID = dialogueID
    }
}

enum InteractionAction {
    case unlock
    case transform
    case trigger
    case collect
}

enum InteractionCondition {
    case hasItem(String)
    case locationIs(String)
    case puzzleSolved(String)
    case characterMet(String)
}

// CombinationRecipe and CombinationAnimation moved to ItemCombinationSystem.swift to avoid duplication

extension Entity {
    var requiresTool: Bool {
        return self.get(InteractableComponent.self)?.requiresTool ?? false
    }
    
    var type: EntityType {
        return self.get(InteractableComponent.self)?.entityType ?? .object
    }
}

enum EntityType {
    case door
    case container
    case character
    case object
    case hotspot
}


extension GameState {
    static let shared = GameState()
    var charactersmet: Set<String> { return Set<String>() }
}