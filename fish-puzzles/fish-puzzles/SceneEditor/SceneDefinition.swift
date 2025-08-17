//
//  SceneDefinition.swift
//  fish-puzzles
//
//  JSON-based scene definition structure for level authoring
//

import Foundation
import CoreGraphics

struct SceneDefinition: Codable {
    let sceneId: String
    let metadata: SceneMetadata
    let settings: SceneSettings
    let entities: [EntityDefinition]
    let puzzles: [PuzzleDefinition]
    let triggers: [TriggerDefinition]
    
    struct SceneMetadata: Codable {
        let name: String
        let author: String
        let version: String
        let createdAt: Date
        let modifiedAt: Date?
    }
    
    struct SceneSettings: Codable {
        let backgroundImage: String
        let backgroundMusic: String?
        let ambientSound: String?
        let lightingPreset: String
        let cameraLimits: CameraLimits?
        
        struct CameraLimits: Codable {
            let minX: CGFloat
            let maxX: CGFloat
            let minY: CGFloat
            let maxY: CGFloat
        }
    }
}

struct EntityDefinition: Codable {
    let id: String
    let type: EntityType
    let position: Position
    let components: [String: ComponentData]
    
    enum EntityType: String, Codable {
        case treasureChest = "treasure_chest"
        case bookshelf = "bookshelf"
        case rock = "rock"
        case npc = "npc"
        case item = "item"
        case decoration = "decoration"
        case trigger = "trigger"
        case custom = "custom"
    }
    
    struct Position: Codable {
        let x: CGFloat
        let y: CGFloat
        let z: Int?
    }
}

struct ComponentData: Codable {
    let type: ComponentType
    let properties: [String: AnyCodable]
    
    enum ComponentType: String, Codable {
        case sprite
        case interaction
        case navigation
        case animation
        case dialogue
        case inventory
        case physics
    }
}

struct PuzzleDefinition: Codable {
    let id: String
    let template: PuzzleTemplate
    let config: PuzzleConfiguration
    
    enum PuzzleTemplate: String, Codable {
        case itemCombination = "item_combination"
        case sequenceLock = "sequence_lock"
        case patternMatch = "pattern_match"
        case findHiddenObject = "find_hidden_object"
        case characterDialogue = "character_dialogue"
        case timedChallenge = "timed_challenge"
        case memoryGame = "memory_game"
        case sortingPuzzle = "sorting_puzzle"
    }
    
    struct PuzzleConfiguration: Codable {
        let difficulty: Difficulty
        let hints: [String]
        let solution: [String: AnyCodable]
        let rewards: [String]
        let requiredItems: [String]?
        let timeLimit: TimeInterval?
        
        enum Difficulty: String, Codable {
            case easy
            case medium
            case hard
        }
    }
}

struct TriggerDefinition: Codable {
    let id: String
    let event: TriggerEvent
    let condition: TriggerCondition?
    let action: TriggerAction
    let params: [String: AnyCodable]
    
    enum TriggerEvent: String, Codable {
        case onSceneLoad = "on_scene_load"
        case onSceneExit = "on_scene_exit"
        case onItemCollected = "on_item_collected"
        case onPuzzleSolved = "on_puzzle_solved"
        case onDialogueComplete = "on_dialogue_complete"
        case onAreaEntered = "on_area_entered"
        case onTimeElapsed = "on_time_elapsed"
    }
    
    struct TriggerCondition: Codable {
        let type: ConditionType
        let value: AnyCodable
        
        enum ConditionType: String, Codable {
            case hasItem = "has_item"
            case puzzleSolved = "puzzle_solved"
            case flagSet = "flag_set"
            case timeOfDay = "time_of_day"
        }
    }
    
    enum TriggerAction: String, Codable {
        case playDialogue = "play_dialogue"
        case showCutscene = "show_cutscene"
        case spawnEntity = "spawn_entity"
        case removeEntity = "remove_entity"
        case changeScene = "change_scene"
        case giveItem = "give_item"
        case setFlag = "set_flag"
        case playSound = "play_sound"
    }
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

class SceneLoader {
    static func loadScene(from url: URL) throws -> SceneDefinition {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SceneDefinition.self, from: data)
    }
    
    static func saveScene(_ scene: SceneDefinition, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(scene)
        try data.write(to: url)
    }
    
    static func createEmptyScene(id: String, name: String, author: String) -> SceneDefinition {
        return SceneDefinition(
            sceneId: id,
            metadata: SceneDefinition.SceneMetadata(
                name: name,
                author: author,
                version: "1.0.0",
                createdAt: Date(),
                modifiedAt: nil
            ),
            settings: SceneDefinition.SceneSettings(
                backgroundImage: "default_background.png",
                backgroundMusic: nil,
                ambientSound: nil,
                lightingPreset: "bright_day",
                cameraLimits: nil
            ),
            entities: [],
            puzzles: [],
            triggers: []
        )
    }
}