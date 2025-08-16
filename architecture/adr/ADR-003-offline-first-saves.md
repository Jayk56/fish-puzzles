# ADR-003: Offline-First Save System with CloudKit Sync

## Status
Accepted

## Context
The game requires a robust save system that:
- Works without internet connection (critical for kids who may use parent's devices offline)
- Syncs across devices when online (iCloud family sharing)
- Handles conflicts gracefully
- Complies with COPPA/privacy requirements
- Provides both auto-save and manual save slots

## Decision
Implement an offline-first save architecture using:
- **Local persistence**: CoreData for structured save data
- **Cloud sync**: CloudKit private database for cross-device sync
- **Conflict resolution**: Last-write-wins with local backup
- **Save slots**: 3 manual + 1 auto-save slot per iCloud account

## Architecture
```swift
class SaveManager {
    // Local save immediate
    func saveLocal(_ gameState: GameState) async
    
    // CloudKit sync when available
    func syncToCloud() async
    
    // Conflict resolution
    func resolveConflict(_ local: GameState, _ cloud: GameState) -> GameState
}

struct SaveGame: Codable {
    let version: Int
    let timestamp: Date
    let playTime: TimeInterval
    let currentScene: String
    let inventory: [Item]
    let completedPuzzles: Set<String>
    let collectedItems: Set<String>
    let settings: GameSettings
}
```

## Consequences

### Positive
- **Always playable**: Game works without internet
- **Automatic sync**: Seamless experience across devices
- **Privacy compliant**: Uses Apple's privacy-first infrastructure
- **No backend costs**: CloudKit included with developer account
- **Parental control**: Tied to iCloud Family Sharing
- **Reliable**: Local saves persist even if cloud fails

### Negative
- **Apple ecosystem only**: No Android/web sync possible
- **CloudKit complexity**: Requires careful error handling
- **Conflict handling**: Potential for save game confusion
- **iCloud dependency**: Requires iCloud account for sync

### Risks
- **Data loss**: Mitigated by local backups and versioning
- **Sync conflicts**: Mitigated by timestamp-based resolution
- **CloudKit quotas**: Monitor usage, implement cleanup

## Alternatives Considered

1. **CloudKit only**: Simpler but requires internet
   - Rejected: Kids often play offline

2. **Local only**: No complexity but no sync
   - Rejected: Parents expect cross-device play

3. **Third-party backend**: Firebase, PlayFab
   - Rejected: Privacy concerns, ongoing costs

4. **Game Center**: Apple's gaming service
   - Rejected: Limited save game support

## Privacy Considerations
- No PII in save games
- Anonymous device ID only
- Private CloudKit database
- No analytics on save data
- Parent can delete via iCloud settings

## References
- [CloudKit Best Practices](https://developer.apple.com/documentation/cloudkit/managing_icloud_containers)
- [COPPA Compliance](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)