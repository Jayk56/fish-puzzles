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
