# ADR-004: Privacy-First Analytics Architecture

## Status
Accepted

## Context
The game needs analytics to understand player behavior and improve the experience, but must:
- Comply with COPPA (Children's Online Privacy Protection Act)
- Meet App Store Kids Category requirements
- Respect user privacy absolutely
- Avoid any third-party tracking
- Provide value without identifying users

## Decision
Build a custom, privacy-first analytics system that:
- Collects only anonymous, aggregate gameplay metrics
- Stores data locally first, uploads in batches
- Uses differential privacy techniques
- No device fingerprinting or user identification
- Parents can disable via Settings

## Implementation
```swift
class PrivacyFirstAnalytics {
    // Only gameplay events, no PII
    enum Event {
        case sceneCompleted(scene: String, duration: TimeInterval)
        case puzzleSolved(puzzle: String, hintsUsed: Int)
        case gameCompleted(totalTime: TimeInterval)
        case settingChanged(setting: String, value: Any)
    }
    
    // Local aggregation before upload
    func logEvent(_ event: Event) {
        // Add noise for differential privacy
        // Batch locally
        // Upload only aggregates
    }
    
    // Parent-accessible controls
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "analytics_enabled") }
        set { 
            UserDefaults.standard.set(newValue, forKey: "analytics_enabled")
            if !newValue { clearAllData() }
        }
    }
}
```

## Data Collected (Anonymous Only)
```
✅ Allowed:
- Scene completion rates
- Puzzle solve times (bucketed)
- Hint usage frequency
- Settings preferences
- App crashes (no stack traces with PII)

❌ Not Collected:
- Device IDs
- IP addresses
- Location data
- Account information
- Screenshots
- User-generated content
- Cross-app tracking
```

## Consequences

### Positive
- **COPPA compliant**: No PII collection from children
- **Parent trust**: Transparent, controllable analytics
- **App Store approval**: Meets Kids Category requirements
- **No third-party risk**: No external SDKs or services
- **Future-proof**: Complies with strictest privacy laws

### Negative
- **Limited insights**: Can't track individual user journeys
- **No cohort analysis**: Can't segment users
- **Development overhead**: Custom implementation required
- **No industry tools**: Can't use Google Analytics, Mixpanel, etc.

## Alternatives Considered

1. **No analytics**: Safest but no insights
   - Rejected: Need basic metrics for improvement

2. **GameAnalytics Kids SDK**: Supposedly COPPA-compliant
   - Rejected: Still third-party, trust concerns

3. **Apple App Analytics**: Apple's own service
   - Rejected: Limited metrics, not granular enough

4. **Server-side only**: Track only server interactions
   - Rejected: Game is offline-first

## Privacy Implementation Details

### Differential Privacy
```swift
// Add noise to metrics before aggregation
func addNoise(to value: Double, epsilon: Double = 1.0) -> Double {
    let noise = Laplace.sample(scale: 1.0 / epsilon)
    return value + noise
}
```

### Data Retention
- Local: 30 days rolling window
- Uploaded: Immediate aggregation, no raw storage
- Crash logs: 7 days, auto-deleted

### Parental Gate
- Analytics toggle behind parental gate
- Clear data option
- Export data option (GDPR compliance)

## Compliance Checklist
- [x] No PII collection
- [x] No persistent identifiers
- [x] No third-party sharing
- [x] Parental control
- [x] Data minimization
- [x] Purpose limitation
- [x] Transparent privacy policy

## References
- [COPPA Rule](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa)
- [Apple - Kids Apps](https://developer.apple.com/app-store/kids-apps/)
- [Differential Privacy](https://privacytools.seas.harvard.edu/differential-privacy)