//
//  ItemCombinationSystem.swift
//  fish-puzzles
//
//  Item combination logic for puzzle solving
//

import Foundation

enum CombinationAnimation {
    case squish
    case bind
    case swirl
    case merge
    case sparkle
}

struct CombinationRecipe {
    let id: String
    let ingredients: Set<String>
    let result: String
    let description: String
    // Additional fields for ItemInteractionEngine compatibility
    let inputs: [String]
    let outputID: String
    let outputName: String
    let outputDisplayName: String
    let outputImage: String
    let outputDescription: String
    let animation: CombinationAnimation?
    
    // Convenience initializer for simple recipes
    init(id: String, ingredients: Set<String>, result: String, description: String) {
        self.id = id
        self.ingredients = ingredients
        self.result = result
        self.description = description
        self.inputs = Array(ingredients)
        self.outputID = result
        self.outputName = result
        self.outputDisplayName = result
        self.outputImage = result
        self.outputDescription = description
        self.animation = nil
    }
    
    // Full initializer for complex recipes
    init(id: String, ingredients: Set<String>, result: String, description: String,
         inputs: [String], outputID: String, outputName: String, outputDisplayName: String,
         outputImage: String, outputDescription: String, animation: CombinationAnimation?) {
        self.id = id
        self.ingredients = ingredients
        self.result = result
        self.description = description
        self.inputs = inputs
        self.outputID = outputID
        self.outputName = outputName
        self.outputDisplayName = outputDisplayName
        self.outputImage = outputImage
        self.outputDescription = outputDescription
        self.animation = animation
    }
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