//
//  HintOverlay.swift
//  fish-puzzles
//
//  Hint system overlay
//

import SpriteKit

class HintOverlay: BaseOverlay {
    enum HintLevel {
        case subtle
        case moderate
        case explicit

        var color: UIColor {
            switch self {
            case .subtle: return UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.95)
            case .moderate: return UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 0.95)
            case .explicit: return UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 0.95)
            }
        }

        var icon: String {
            switch self {
            case .subtle: return "?"
            case .moderate: return "💡"
            case .explicit: return "!"
            }
        }
    }

    private var hintBubble: SKShapeNode!
    private var hintText: SKLabelNode!
    private var hintIcon: SKLabelNode!
    private var currentLevel: HintLevel = .subtle
    private var hintTimer: TimeInterval = 0
    private let hintDuration: TimeInterval = 5.0
    private var lastHintTime: TimeInterval = 0
    private let hintCooldown: TimeInterval = 30.0

    init(size: CGSize) {
        super.init(layer: .hint, size: size)
        self.isModal = false
        self.dimBackground = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupOverlay() {
        setupHintBubble()
        setupHintText()
        setupHintIcon()
    }

    private func setupHintBubble() {
        let bubbleSize = CGSize(width: 300, height: 100)
        hintBubble = SKShapeNode(rectOf: bubbleSize, cornerRadius: 20)
        hintBubble.fillColor = currentLevel.color
        hintBubble.strokeColor = .white
        hintBubble.lineWidth = 2
        hintBubble.glowWidth = 5
        // Position hint well above the persistent bar
        // The overlay is centered in the screen, so we need to position relative to center
        // Put it in the upper third of the screen to avoid any overlap with bottom UI
        hintBubble.position = CGPoint(x: 0, y: overlaySize.height / 4)
        hintBubble.zPosition = 0

        let tail = SKShapeNode()
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -20, y: -bubbleSize.height / 2))
        tailPath.addLine(to: CGPoint(x: 0, y: -bubbleSize.height / 2 - 20))
        tailPath.addLine(to: CGPoint(x: 20, y: -bubbleSize.height / 2))
        tail.path = tailPath
        tail.fillColor = currentLevel.color
        tail.strokeColor = .white
        tail.lineWidth = 2
        tail.zPosition = -1
        hintBubble.addChild(tail)

        addChild(hintBubble)
    }

    private func setupHintIcon() {
        hintIcon = SKLabelNode(text: currentLevel.icon)
        hintIcon.fontSize = 32
        let bubbleSize = CGSize(width: 300, height: 100)
        hintIcon.position = CGPoint(x: -bubbleSize.width / 2 + 30, y: 0)
        hintIcon.zPosition = 2
        hintBubble.addChild(hintIcon)
    }

    private func setupHintText() {
        hintText = SKLabelNode(text: "")
        hintText.fontName = "AvenirNext-Regular"
        hintText.fontSize = 16
        hintText.horizontalAlignmentMode = .center
        hintText.verticalAlignmentMode = .center
        hintText.position = CGPoint(x: 20, y: 0)
        let bubbleSize = CGSize(width: 300, height: 100)
        hintText.preferredMaxLayoutWidth = bubbleSize.width - 80
        hintText.numberOfLines = 0
        hintText.zPosition = 2
        hintBubble.addChild(hintText)
    }

    func showHint(_ text: String, level: HintLevel = .subtle, position: CGPoint? = nil) {
        guard CACurrentMediaTime() - lastHintTime >= hintCooldown else { return }

        currentLevel = level
        hintText.text = text
        hintIcon.text = level.icon
        hintBubble.fillColor = level.color

        if let pos = position {
            hintBubble.position = pos
        }

        hintTimer = 5
        lastHintTime = CACurrentMediaTime()

        show(animated: true)
    }

    override func update(deltaTime: TimeInterval) {
        guard !isHidden else { return }

        hintTimer += deltaTime

        if hintTimer >= hintDuration {
            hide(animated: true)
        }
    }

    override func show(animated: Bool) {
        super.show(animated: animated)

        if animated {
            hintBubble.removeAllActions()

            let appear = SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3),
            ])

            let bounce = SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.2),
            ])

            hintBubble.run(SKAction.sequence([appear, bounce]))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if hint bubble was tapped
        if hintBubble.contains(location) {
            hudManager?.hide(.hint)
        }
    }

    func getNextHintLevel() -> HintLevel {
        switch currentLevel {
        case .subtle: return .moderate
        case .moderate: return .explicit
        case .explicit: return .explicit
        }
    }

    func resetHintLevel() {
        currentLevel = .subtle
    }

    func isHintAvailable() -> Bool {
        return CACurrentMediaTime() - lastHintTime >= hintCooldown
    }

    func getTimeUntilNextHint() -> TimeInterval {
        let timeSinceLastHint = CACurrentMediaTime() - lastHintTime
        return max(0, hintCooldown - timeSinceLastHint)
    }
}
