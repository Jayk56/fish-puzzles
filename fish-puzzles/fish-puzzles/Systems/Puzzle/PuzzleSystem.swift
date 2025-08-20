//
//  PuzzleSystem.swift
//  fish-puzzles
//
//  Base puzzle system and protocol definitions
//

import Foundation
import SpriteKit

protocol PuzzleDelegate: AnyObject {
    func puzzleDidStart(_ puzzle: Puzzle)
    func puzzleDidUpdate(_ puzzle: Puzzle, progress: Float)
    func puzzleDidComplete(_ puzzle: Puzzle)
    func puzzleDidFail(_ puzzle: Puzzle)
    func puzzleDidProvideHint(_ puzzle: Puzzle, hint: String)
}

enum PuzzleState {
    case inactive
    case active
    case completed
    case failed
}

enum PuzzleType {
    case keyLock
    case itemCombination
    case sequence
    case environmental
    case dialogue
    case collection
    case hiddenObject
    case miniGame
}

class Puzzle {
    let id: String
    let type: PuzzleType
    var state: PuzzleState = .inactive
    weak var delegate: PuzzleDelegate?
    
    var requiredItems: [String] = []
    var collectedItems: [String] = []
    var hints: [String] = []
    var currentHintIndex: Int = 0
    var progress: Float = 0.0
    
    init(id: String, type: PuzzleType) {
        self.id = id
        self.type = type
    }
    
    func start() {
        guard state == .inactive else { return }
        state = .active
        delegate?.puzzleDidStart(self)
        onStart()
    }
    
    func update(deltaTime: TimeInterval) {
        guard state == .active else { return }
        onUpdate(deltaTime: deltaTime)
    }
    
    func complete() {
        guard state == .active else { return }
        state = .completed
        progress = 1.0
        delegate?.puzzleDidComplete(self)
        onComplete()
    }
    
    func fail() {
        guard state == .active else { return }
        state = .failed
        delegate?.puzzleDidFail(self)
        onFail()
    }
    
    func reset() {
        state = .inactive
        progress = 0.0
        collectedItems.removeAll()
        currentHintIndex = 0
        onReset()
    }
    
    func provideHint() {
        guard currentHintIndex < hints.count else { return }
        let hint = hints[currentHintIndex]
        currentHintIndex += 1
        delegate?.puzzleDidProvideHint(self, hint: hint)
    }
    
    func checkCompletion() -> Bool {
        return onCheckCompletion()
    }
    
    func handleInteraction(with item: String) {
        onHandleInteraction(with: item)
    }
    
    // Override points for subclasses
    func onStart() {}
    func onUpdate(deltaTime: TimeInterval) {}
    func onComplete() {}
    func onFail() {}
    func onReset() {}
    func onCheckCompletion() -> Bool { return false }
    func onHandleInteraction(with item: String) {}
}

class PuzzleManager {
    static let shared = PuzzleManager()
    
    private var puzzles: [String: Puzzle] = [:]
    private var activePuzzle: Puzzle?
    
    private init() {}
    
    func register(_ puzzle: Puzzle) {
        puzzles[puzzle.id] = puzzle
    }
    
    func unregister(_ puzzleId: String) {
        puzzles.removeValue(forKey: puzzleId)
    }
    
    func getPuzzle(by id: String) -> Puzzle? {
        return puzzles[id]
    }
    
    func startPuzzle(_ puzzleId: String) {
        guard let puzzle = puzzles[puzzleId] else { return }
        activePuzzle?.reset()
        activePuzzle = puzzle
        puzzle.start()
    }
    
    func update(deltaTime: TimeInterval) {
        activePuzzle?.update(deltaTime: deltaTime)
    }
    
    func getActivePuzzle() -> Puzzle? {
        return activePuzzle
    }
    
    func resetAll() {
        puzzles.values.forEach { $0.reset() }
        activePuzzle = nil
    }
}