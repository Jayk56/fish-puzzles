//
//  KeyLockPuzzle.swift
//  fish-puzzles
//
//  Key and lock puzzle implementation
//

import Foundation

class KeyLockPuzzle: Puzzle {
    private var keyId: String
    private var lockId: String
    private var hasKey: Bool = false
    private var isUnlocked: Bool = false
    
    init(id: String, keyId: String, lockId: String) {
        self.keyId = keyId
        self.lockId = lockId
        super.init(id: id, type: .keyLock)
        
        self.requiredItems = [keyId]
        self.hints = [
            "Look for something that might open this lock.",
            "The key might be hidden somewhere in this area.",
            "Try checking behind objects or talking to characters."
        ]
    }
    
    override func onHandleInteraction(with item: String) {
        if item == keyId && !hasKey {
            hasKey = true
            collectedItems.append(item)
            progress = 0.5
            delegate?.puzzleDidUpdate(self, progress: progress)
        } else if item == lockId && hasKey && !isUnlocked {
            isUnlocked = true
            progress = 1.0
            complete()
        } else if item == lockId && !hasKey {
            provideHint()
        }
    }
    
    override func onCheckCompletion() -> Bool {
        return isUnlocked
    }
    
    override func onReset() {
        hasKey = false
        isUnlocked = false
    }
}