//
//  ItemCombinationSystem.swift
//  fish-puzzles
//
//  Item combination logic for puzzle solving
//

import Foundation

struct CombinationRecipe {
    let id: String
    let ingredients: Set<String>
    let result: String
    let description: String
}

protocol ItemCombinationDelegate: AnyObject {
    func itemCombinationSucceeded(result: String, from ingredients: [String])
    func itemCombinationFailed(ingredients: [String])
}

class ItemCombinationSystem {
    static let shared = ItemCombinationSystem()
    
    private var recipes: [String: CombinationRecipe] = [:]
    weak var delegate: ItemCombinationDelegate?
    
    private init() {
        loadDefaultRecipes()
    }
    
    private func loadDefaultRecipes() {
        // Example recipes - these would be loaded from data files
        addRecipe(CombinationRecipe(
            id: "rope_hook",
            ingredients: ["rope", "hook"],
            result: "grappling_hook",
            description: "Combine rope with hook to make a grappling hook"
        ))
        
        addRecipe(CombinationRecipe(
            id: "key_parts",
            ingredients: ["key_half_1", "key_half_2"],
            result: "complete_key",
            description: "Combine key halves to make a complete key"
        ))
    }
    
    func addRecipe(_ recipe: CombinationRecipe) {
        recipes[recipe.id] = recipe
    }
    
    func removeRecipe(_ recipeId: String) {
        recipes.removeValue(forKey: recipeId)
    }
    
    func canCombine(_ items: [String]) -> Bool {
        let itemSet = Set(items)
        return recipes.values.contains { $0.ingredients == itemSet }
    }
    
    func combine(_ items: [String]) -> String? {
        let itemSet = Set(items)
        
        for recipe in recipes.values {
            if recipe.ingredients == itemSet {
                delegate?.itemCombinationSucceeded(result: recipe.result, from: items)
                return recipe.result
            }
        }
        
        delegate?.itemCombinationFailed(ingredients: items)
        return nil
    }
    
    func getRecipe(for result: String) -> CombinationRecipe? {
        return recipes.values.first { $0.result == result }
    }
    
    func getRecipes(containing item: String) -> [CombinationRecipe] {
        return recipes.values.filter { $0.ingredients.contains(item) }
    }
}

class ItemCombinationPuzzle: Puzzle {
    private var recipe: CombinationRecipe
    private var hasAllIngredients: Bool = false
    private var hasCombined: Bool = false
    
    init(id: String, recipe: CombinationRecipe) {
        self.recipe = recipe
        super.init(id: id, type: .itemCombination)
        
        self.requiredItems = Array(recipe.ingredients)
        self.hints = [
            "Try combining items in your inventory.",
            "These items might work together somehow.",
            recipe.description
        ]
    }
    
    override func onHandleInteraction(with item: String) {
        if recipe.ingredients.contains(item) && !collectedItems.contains(item) {
            collectedItems.append(item)
            progress = Float(collectedItems.count) / Float(recipe.ingredients.count) * 0.8
            delegate?.puzzleDidUpdate(self, progress: progress)
            
            if Set(collectedItems) == recipe.ingredients {
                hasAllIngredients = true
            }
        }
    }
    
    func attemptCombination(_ items: [String]) -> Bool {
        guard hasAllIngredients else { return false }
        
        if let result = ItemCombinationSystem.shared.combine(items) {
            if result == recipe.result {
                hasCombined = true
                complete()
                return true
            }
        }
        return false
    }
    
    override func onCheckCompletion() -> Bool {
        return hasCombined
    }
    
    override func onReset() {
        hasAllIngredients = false
        hasCombined = false
    }
}