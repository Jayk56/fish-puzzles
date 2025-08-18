//
//  SettingsOverlay.swift
//  fish-puzzles
//
//  Settings and sound control overlay
//

import SpriteKit

class SettingsOverlay: BaseOverlay {
    private var settingsBackground: SKShapeNode!
    private var closeButton: CloseButton!
    
    // Pages container
    private var pagesContainer: SKNode!
    private var currentPage = 0
    private let totalPages = 3
    
    // Page 1 - Audio controls
    private var masterVolumeSlider: SliderControl!
    private var musicVolumeSlider: SliderControl!
    
    // Page 2 - Sound & Accessibility
    private var sfxVolumeSlider: SliderControl!
    private var subtitlesToggle: ToggleControl!
    
    // Page 3 - Additional settings
    private var voiceOverToggle: ToggleControl!
    
    // Navigation
    private var prevButton: SKShapeNode!
    private var nextButton: SKShapeNode!
    private var pageIndicators: [SKShapeNode] = []
    
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
        setupPagesContainer()
        setupControls()
        setupNavigation()
        setupCloseButton()
        showPage(0)
    }
    
    private func setupBackground() {
        let bgSize = CGSize(width: overlaySize.width * 0.7, height: overlaySize.height * 0.8)
        settingsBackground = SKShapeNode(rectOf: bgSize, cornerRadius: 20)
        settingsBackground.fillColor = UIColor(white: 0.15, alpha: 0.95)
        settingsBackground.strokeColor = .white
        settingsBackground.lineWidth = 3
        settingsBackground.position = CGPoint.zero
        settingsBackground.zPosition = 0
        
        addChild(settingsBackground)
        
        let title = SKLabelNode(text: "Settings")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 32
        title.position = CGPoint(x: 0, y: bgSize.height/2 - 50)
        title.zPosition = 2
        settingsBackground.addChild(title)
    }
    
    private func setupPagesContainer() {
        pagesContainer = SKNode()
        pagesContainer.zPosition = 1
        settingsBackground.addChild(pagesContainer)
    }
    
    private func setupControls() {
        let startY: CGFloat = 40  // Moved down from 100
        let spacing: CGFloat = 80
        
        // Page 1 - Audio Controls
        masterVolumeSlider = SliderControl(
            label: "Master Volume",
            value: UserDefaults.standard.float(forKey: "masterVolume")
        )
        masterVolumeSlider.position = CGPoint(x: 0, y: startY)
        masterVolumeSlider.zPosition = 2
        masterVolumeSlider.onValueChanged = { value in
            UserDefaults.standard.set(value, forKey: "masterVolume")
            GameEngine.shared.updateVolume(music: value, sfx: value)
        }
        masterVolumeSlider.name = "page0"
        pagesContainer.addChild(masterVolumeSlider)
        
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
        musicVolumeSlider.name = "page0"
        pagesContainer.addChild(musicVolumeSlider)
        
        // Page 2 - Sound & Accessibility
        sfxVolumeSlider = SliderControl(
            label: "Sound Effects",
            value: GameEngine.shared.gameState.sfxVolume
        )
        sfxVolumeSlider.position = CGPoint(x: 0, y: startY)
        sfxVolumeSlider.zPosition = 2
        sfxVolumeSlider.onValueChanged = { value in
            UserDefaults.standard.set(value, forKey: "sfxVolume")
            GameEngine.shared.updateVolume(sfx: value)
        }
        sfxVolumeSlider.name = "page1"
        sfxVolumeSlider.isHidden = true
        pagesContainer.addChild(sfxVolumeSlider)
        
        subtitlesToggle = ToggleControl(
            label: "Subtitles",
            isOn: GameEngine.shared.gameState.subtitlesEnabled
        )
        subtitlesToggle.position = CGPoint(x: 0, y: startY - spacing)
        subtitlesToggle.zPosition = 2
        subtitlesToggle.onToggled = { isOn in
            UserDefaults.standard.set(isOn, forKey: "subtitlesEnabled")
            GameEngine.shared.updateSubtitlesEnabled(isOn)
        }
        subtitlesToggle.name = "page1"
        subtitlesToggle.isHidden = true
        pagesContainer.addChild(subtitlesToggle)
        
        // Page 3 - Additional Settings
        voiceOverToggle = ToggleControl(
            label: "Voice Over",
            isOn: UserDefaults.standard.bool(forKey: "voiceOverEnabled")
        )
        voiceOverToggle.position = CGPoint(x: 0, y: startY)
        voiceOverToggle.zPosition = 2
        voiceOverToggle.onToggled = { isOn in
            UserDefaults.standard.set(isOn, forKey: "voiceOverEnabled")
        }
        voiceOverToggle.name = "page2"
        voiceOverToggle.isHidden = true
        pagesContainer.addChild(voiceOverToggle)
    }
    
    private func setupNavigation() {
        let bgSize = CGSize(width: overlaySize.width * 0.7, height: overlaySize.height * 0.8)
        
        // Previous button
        prevButton = SKShapeNode(circleOfRadius: 25)
        prevButton.fillColor = UIColor(white: 0.3, alpha: 0.8)
        prevButton.strokeColor = .white
        prevButton.lineWidth = 2
        prevButton.position = CGPoint(x: -bgSize.width/2 + 60, y: -bgSize.height/2 + 60)
        prevButton.zPosition = 3
        
        let prevArrow = SKLabelNode(text: "◀")
        prevArrow.fontSize = 20
        prevArrow.verticalAlignmentMode = .center
        prevButton.addChild(prevArrow)
        
        settingsBackground.addChild(prevButton)
        
        // Next button
        nextButton = SKShapeNode(circleOfRadius: 25)
        nextButton.fillColor = UIColor(white: 0.3, alpha: 0.8)
        nextButton.strokeColor = .white
        nextButton.lineWidth = 2
        nextButton.position = CGPoint(x: bgSize.width/2 - 60, y: -bgSize.height/2 + 60)
        nextButton.zPosition = 3
        
        let nextArrow = SKLabelNode(text: "▶")
        nextArrow.fontSize = 20
        nextArrow.verticalAlignmentMode = .center
        nextButton.addChild(nextArrow)
        
        settingsBackground.addChild(nextButton)
        
        // Page indicators
        let indicatorSpacing: CGFloat = 20
        let startX = -CGFloat(totalPages - 1) * indicatorSpacing / 2
        
        for i in 0..<totalPages {
            let indicator = SKShapeNode(circleOfRadius: 5)
            indicator.fillColor = i == 0 ? .white : UIColor(white: 0.5, alpha: 0.5)
            indicator.strokeColor = .clear
            indicator.position = CGPoint(x: startX + CGFloat(i) * indicatorSpacing, 
                                       y: -bgSize.height/2 + 60)
            indicator.zPosition = 3
            pageIndicators.append(indicator)
            settingsBackground.addChild(indicator)
        }
    }
    
    private func showPage(_ pageIndex: Int) {
        currentPage = pageIndex
        
        // Hide all controls
        pagesContainer.enumerateChildNodes(withName: "//page*") { node, _ in
            node.isHidden = true
        }
        
        // Show current page controls
        pagesContainer.enumerateChildNodes(withName: "page\(pageIndex)") { node, _ in
            node.isHidden = false
        }
        
        // Update navigation buttons
        prevButton.alpha = currentPage > 0 ? 1.0 : 0.3
        nextButton.alpha = currentPage < totalPages - 1 ? 1.0 : 0.3
        
        // Update page indicators
        for (index, indicator) in pageIndicators.enumerated() {
            indicator.fillColor = index == currentPage ? .white : UIColor(white: 0.5, alpha: 0.5)
        }
    }
    
    private func setupCloseButton() {
        closeButton = CloseButton()
        let bgSize = CGSize(width: overlaySize.width * 0.7, height: overlaySize.height * 0.8)
        closeButton.position = CGPoint(
            x: bgSize.width/2 - 30,
            y: bgSize.height/2 - 30
        )
        closeButton.zPosition = 3
        closeButton.onTap = { [weak self] in
            self?.hudManager?.hide(.settings)
        }
        
        settingsBackground.addChild(closeButton)
    }
    
    private var activeSlider: SliderControl?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let localPoint = convert(location, to: settingsBackground)
        
        // Check navigation buttons
        if prevButton.contains(localPoint) && currentPage > 0 {
            showPage(currentPage - 1)
            AudioManager.shared.playSFX("tap")
            return
        }
        
        if nextButton.contains(localPoint) && currentPage < totalPages - 1 {
            showPage(currentPage + 1)
            AudioManager.shared.playSFX("tap")
            return
        }
        
        // Check visible controls based on current page
        let visibleControls: [Any?]
        switch currentPage {
        case 0:
            visibleControls = [masterVolumeSlider, musicVolumeSlider]
        case 1:
            visibleControls = [sfxVolumeSlider, subtitlesToggle]
        case 2:
            visibleControls = [voiceOverToggle]
        default:
            return
        }
        
        for control in visibleControls {
            if let control = control {
                let controlPoint = pagesContainer.convert(localPoint, to: control as! SKNode)
                if let slider = control as? SliderControl {
                    if slider.handleTouch(at: controlPoint) {
                        activeSlider = slider
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
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let slider = activeSlider else { return }
        let location = touch.location(in: self)
        let sliderPoint = convert(location, to: slider)
        slider.handleDrag(at: sliderPoint)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSlider = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSlider = nil
    }
}

class SliderControl: SKNode {
    private var label: SKLabelNode!
    private var track: SKShapeNode!
    private var thumb: SKShapeNode!
    private var valueLabel: SKLabelNode!
    private let trackLength: CGFloat = 120  // Shortened from 200
    
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
        trackPath.addLine(to: CGPoint(x: trackLength, y: 0))
        
        track = SKShapeNode(path: trackPath)
        track.strokeColor = .gray
        track.lineWidth = 4
        track.position = CGPoint(x: -20, y: 0)
        addChild(track)
        
        // Add filled portion of track
        let filledTrack = SKShapeNode(path: trackPath)
        filledTrack.strokeColor = .cyan
        filledTrack.lineWidth = 4
        filledTrack.zPosition = -1
        track.addChild(filledTrack)
        
        thumb = SKShapeNode(circleOfRadius: 12)
        thumb.fillColor = .white
        thumb.strokeColor = .cyan
        thumb.lineWidth = 2
        thumb.position = CGPoint(x: -20 + CGFloat(value) * trackLength, y: 0)
        addChild(thumb)
        
        valueLabel = SKLabelNode(text: "\(Int(value * 100))%")
        valueLabel.fontName = "AvenirNext-Regular"
        valueLabel.fontSize = 14
        valueLabel.horizontalAlignmentMode = .left
        valueLabel.position = CGPoint(x: trackLength + 10, y: 0)
        addChild(valueLabel)
        
        updateThumbPosition()
    }
    
    private func updateThumbPosition() {
        thumb.position.x = -20 + CGFloat(value) * trackLength
        valueLabel.text = "\(Int(value * 100))%"
    }
    
    func handleTouch(at point: CGPoint) -> Bool {
        let expandedBounds = CGRect(x: -30, y: -25, width: trackLength + 20, height: 50)
        
        if expandedBounds.contains(point) {
            updateValue(at: point)
            return true
        }
        
        return false
    }
    
    func handleDrag(at point: CGPoint) {
        updateValue(at: point)
    }
    
    private func updateValue(at point: CGPoint) {
        let normalizedX = (point.x + 20) / trackLength
        value = Float(max(0, min(1, normalizedX)))
    }
}

class ToggleControl: SKNode {
    private var label: SKLabelNode!
    private var toggleBackground: SKShapeNode!
    private var toggleThumb: SKShapeNode!
    
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
        
        toggleBackground = SKShapeNode(rectOf: CGSize(width: 60, height: 30), cornerRadius: 15)
        toggleBackground.fillColor = .gray
        toggleBackground.strokeColor = .white
        toggleBackground.lineWidth = 2
        toggleBackground.position = CGPoint(x: 50, y: 0)
        addChild(toggleBackground)
        
        toggleThumb = SKShapeNode(circleOfRadius: 13)
        toggleThumb.fillColor = .white
        toggleThumb.strokeColor = .clear
        toggleThumb.position = CGPoint(x: isOn ? 15 : -15, y: 0)
        toggleBackground.addChild(toggleThumb)
        
        updateToggleAppearance()
    }
    
    private func updateToggleAppearance() {
        toggleBackground.fillColor = isOn ? .green : .gray
        
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