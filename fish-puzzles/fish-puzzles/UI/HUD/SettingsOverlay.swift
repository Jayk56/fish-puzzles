//
//  SettingsOverlay.swift
//  fish-puzzles
//
//  Settings and sound control overlay
//

import SpriteKit

class SettingsOverlay: BaseOverlay {
    private var settingsBackground: SKSpriteNode!
    private var closeButton: CloseButton!
    
    private var masterVolumeSlider: SliderControl!
    private var musicVolumeSlider: SliderControl!
    private var sfxVolumeSlider: SliderControl!
    private var subtitlesToggle: ToggleControl!
    private var voiceOverToggle: ToggleControl!
    
    init(size: CGSize) {
        super.init(layer: .settings, size: size)
        self.isModal = true
        self.dimBackground = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupOverlay() {
        setupBackground()
        setupControls()
        setupCloseButton()
    }
    
    private func setupBackground() {
        let bgSize = CGSize(width: overlaySize.width * 0.7, height: overlaySize.height * 0.8)
        settingsBackground = SKSpriteNode(color: UIColor(white: 0.15, alpha: 0.95), size: bgSize)
        settingsBackground.position = CGPoint.zero
        settingsBackground.zPosition = 0
        
        let border = SKShapeNode(rectOf: bgSize, cornerRadius: 20)
        border.strokeColor = .white
        border.lineWidth = 3
        border.zPosition = 1
        settingsBackground.addChild(border)
        
        addChild(settingsBackground)
        
        let title = SKLabelNode(text: "Settings")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 32
        title.position = CGPoint(x: 0, y: bgSize.height/2 - 50)
        title.zPosition = 2
        settingsBackground.addChild(title)
    }
    
    private func setupControls() {
        let startY: CGFloat = 150
        let spacing: CGFloat = 80
        
        masterVolumeSlider = SliderControl(
            label: "Master Volume",
            value: UserDefaults.standard.float(forKey: "masterVolume")
        )
        masterVolumeSlider.position = CGPoint(x: 0, y: startY)
        masterVolumeSlider.zPosition = 2
        masterVolumeSlider.onValueChanged = { value in
            UserDefaults.standard.set(value, forKey: "masterVolume")
            // Master volume affects both music and sfx
            GameEngine.shared.updateVolume(music: value, sfx: value)
        }
        settingsBackground.addChild(masterVolumeSlider)
        
        musicVolumeSlider = SliderControl(
            label: "Music Volume",
            value: GameEngine.shared.gameState.musicVolume
        )
        musicVolumeSlider.position = CGPoint(x: 0, y: startY - spacing)
        musicVolumeSlider.zPosition = 2
        musicVolumeSlider.onValueChanged = { value in
            UserDefaults.standard.set(value, forKey: "musicVolume")
            GameEngine.shared.updateVolume(music: value)
        }
        settingsBackground.addChild(musicVolumeSlider)
        
        sfxVolumeSlider = SliderControl(
            label: "Sound Effects",
            value: GameEngine.shared.gameState.sfxVolume
        )
        sfxVolumeSlider.position = CGPoint(x: 0, y: startY - spacing * 2)
        sfxVolumeSlider.zPosition = 2
        sfxVolumeSlider.onValueChanged = { value in
            UserDefaults.standard.set(value, forKey: "sfxVolume")
            GameEngine.shared.updateVolume(sfx: value)
        }
        settingsBackground.addChild(sfxVolumeSlider)
        
        subtitlesToggle = ToggleControl(
            label: "Subtitles",
            isOn: GameEngine.shared.gameState.subtitlesEnabled
        )
        subtitlesToggle.position = CGPoint(x: 0, y: startY - spacing * 3)
        subtitlesToggle.zPosition = 2
        subtitlesToggle.onToggled = { isOn in
            UserDefaults.standard.set(isOn, forKey: "subtitlesEnabled")
            GameEngine.shared.updateSubtitlesEnabled(isOn)
        }
        settingsBackground.addChild(subtitlesToggle)
        
        voiceOverToggle = ToggleControl(
            label: "Voice Over",
            isOn: UserDefaults.standard.bool(forKey: "voiceOverEnabled")
        )
        voiceOverToggle.position = CGPoint(x: 0, y: startY - spacing * 4)
        voiceOverToggle.zPosition = 2
        voiceOverToggle.onToggled = { isOn in
            UserDefaults.standard.set(isOn, forKey: "voiceOverEnabled")
            // Voice over setting stored in UserDefaults for now
        }
        settingsBackground.addChild(voiceOverToggle)
    }
    
    private func setupCloseButton() {
        closeButton = CloseButton()
        closeButton.position = CGPoint(
            x: settingsBackground.size.width/2 - 30,
            y: settingsBackground.size.height/2 - 30
        )
        closeButton.zPosition = 3
        closeButton.onTap = { [weak self] in
            self?.hudManager?.hide(.settings)
        }
        
        settingsBackground.addChild(closeButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let localPoint = convert(location, to: settingsBackground)
        
        // Check controls (close button handles itself)
        let controls = [masterVolumeSlider, musicVolumeSlider, sfxVolumeSlider, 
                       subtitlesToggle, voiceOverToggle]
        
        for control in controls {
            if let control = control {
                let controlPoint = settingsBackground.convert(localPoint, to: control)
                if let slider = control as? SliderControl {
                    if slider.handleTouch(at: controlPoint) {
                        return
                    }
                } else if let toggle = control as? ToggleControl {
                    if toggle.handleTouch(at: controlPoint) {
                        return
                    }
                }
            }
        }
    }
}

class SliderControl: SKNode {
    private var label: SKLabelNode!
    private var track: SKShapeNode!
    private var thumb: SKSpriteNode!
    private var valueLabel: SKLabelNode!
    
    var value: Float = 0.5 {
        didSet {
            updateThumbPosition()
            onValueChanged?(value)
        }
    }
    
    var onValueChanged: ((Float) -> Void)?
    
    init(label: String, value: Float = 0.5) {
        super.init()
        self.value = value
        setupControl(label: label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupControl(label labelText: String) {
        label = SKLabelNode(text: labelText)
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 18
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: -150, y: 0)
        addChild(label)
        
        let trackPath = CGMutablePath()
        trackPath.move(to: CGPoint(x: 0, y: 0))
        trackPath.addLine(to: CGPoint(x: 200, y: 0))
        
        track = SKShapeNode(path: trackPath)
        track.strokeColor = .gray
        track.lineWidth = 4
        track.position = CGPoint(x: -50, y: 0)
        addChild(track)
        
        thumb = SKSpriteNode(color: .white, size: CGSize(width: 20, height: 20))
        thumb.position = CGPoint(x: -50 + CGFloat(value) * 200, y: 0)
        addChild(thumb)
        
        valueLabel = SKLabelNode(text: "\(Int(value * 100))%")
        valueLabel.fontName = "AvenirNext-Regular"
        valueLabel.fontSize = 14
        valueLabel.horizontalAlignmentMode = .left
        valueLabel.position = CGPoint(x: 160, y: 0)
        addChild(valueLabel)
        
        updateThumbPosition()
    }
    
    private func updateThumbPosition() {
        thumb.position.x = -50 + CGFloat(value) * 200
        valueLabel.text = "\(Int(value * 100))%"
    }
    
    func handleTouch(at point: CGPoint) -> Bool {
        let trackBounds = CGRect(x: -50, y: -20, width: 200, height: 40)
        
        if trackBounds.contains(point) {
            let normalizedX = (point.x + 50) / 200
            value = Float(max(0, min(1, normalizedX)))
            return true
        }
        
        return false
    }
}

class ToggleControl: SKNode {
    private var label: SKLabelNode!
    private var toggleBackground: SKSpriteNode!
    private var toggleThumb: SKSpriteNode!
    
    var isOn: Bool = false {
        didSet {
            updateToggleAppearance()
            onToggled?(isOn)
        }
    }
    
    var onToggled: ((Bool) -> Void)?
    
    init(label: String, isOn: Bool = false) {
        super.init()
        self.isOn = isOn
        setupControl(label: label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupControl(label labelText: String) {
        label = SKLabelNode(text: labelText)
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 18
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: -150, y: 0)
        addChild(label)
        
        toggleBackground = SKSpriteNode(color: .gray, size: CGSize(width: 60, height: 30))
        toggleBackground.position = CGPoint(x: 50, y: 0)
        addChild(toggleBackground)
        
        let bgShape = SKShapeNode(rectOf: toggleBackground.size, cornerRadius: 15)
        bgShape.strokeColor = .white
        bgShape.lineWidth = 2
        toggleBackground.addChild(bgShape)
        
        toggleThumb = SKSpriteNode(color: .white, size: CGSize(width: 26, height: 26))
        toggleThumb.position = CGPoint(x: isOn ? 15 : -15, y: 0)
        toggleBackground.addChild(toggleThumb)
        
        updateToggleAppearance()
    }
    
    private func updateToggleAppearance() {
        toggleBackground.color = isOn ? .green : .gray
        
        let moveAction = SKAction.move(to: CGPoint(x: isOn ? 15 : -15, y: 0), duration: 0.2)
        toggleThumb.run(moveAction)
    }
    
    func handleTouch(at point: CGPoint) -> Bool {
        let toggleBounds = CGRect(
            x: toggleBackground.position.x - 30,
            y: toggleBackground.position.y - 15,
            width: 60,
            height: 30
        )
        
        if toggleBounds.contains(point) {
            isOn.toggle()
            return true
        }
        
        return false
    }
}