//
//  MapOverlay.swift
//  fish-puzzles
//
//  Map navigation overlay
//

import SpriteKit

class MapOverlay: BaseOverlay {
    private var mapBackground: SKShapeNode!
    private var locationNodes: [LocationNode] = []
    private var currentLocationIndicator: SKShapeNode!
    private var closeButton: CloseButton!
    
    init(size: CGSize) {
        super.init(layer: .map, size: size)
        self.isModal = true
        self.dimBackground = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupOverlay() {
        setupBackground()
        setupLocations()
        setupCurrentLocationIndicator()
        setupCloseButton()
    }
    
    private func setupBackground() {
        let bgSize = CGSize(width: overlaySize.width * 0.9, height: overlaySize.height * 0.8)
        mapBackground = SKShapeNode(rectOf: bgSize, cornerRadius: 20)
        mapBackground.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.95) // Dark navy background
        mapBackground.strokeColor = UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0) // Lighter blue border
        mapBackground.lineWidth = 3
        mapBackground.position = CGPoint.zero
        mapBackground.zPosition = 0
        
        addChild(mapBackground)
        
        let title = SKLabelNode(text: "Map")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 32
        title.position = CGPoint(x: 0, y: bgSize.height/2 - 40)
        title.zPosition = 2
        mapBackground.addChild(title)
    }
    
    private func setupLocations() {
        let locations = [
            (name: "Coral Reef", position: CGPoint(x: -150, y: 50), discovered: true, color: UIColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)),
            (name: "Shipwreck", position: CGPoint(x: 0, y: 0), discovered: true, color: UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)),
            (name: "Deep Cave", position: CGPoint(x: 150, y: -50), discovered: false, color: UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0)),
            (name: "Kelp Forest", position: CGPoint(x: -100, y: -100), discovered: false, color: UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0))
        ]
        
        for location in locations {
            let node = LocationNode(name: location.name, discovered: location.discovered, color: location.color)
            node.position = location.position
            node.zPosition = 2
            mapBackground.addChild(node)
            locationNodes.append(node)
        }
        
        drawConnectionLines()
    }
    
    private func drawConnectionLines() {
        guard locationNodes.count > 1 else { return }
        
        for i in 0..<locationNodes.count - 1 {
            let startNode = locationNodes[i]
            let endNode = locationNodes[i + 1]
            
            if startNode.isDiscovered && endNode.isDiscovered {
                let line = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: startNode.position)
                path.addLine(to: endNode.position)
                line.path = path
                line.strokeColor = UIColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 0.5)
                line.lineWidth = 2
                line.zPosition = 1
                mapBackground.addChild(line)
            }
        }
    }
    
    private func setupCurrentLocationIndicator() {
        currentLocationIndicator = SKShapeNode(circleOfRadius: 15)
        currentLocationIndicator.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        currentLocationIndicator.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 1.0)
        currentLocationIndicator.lineWidth = 2
        currentLocationIndicator.glowWidth = 5
        currentLocationIndicator.zPosition = 3
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        currentLocationIndicator.run(SKAction.repeatForever(pulse))
        
        if let firstLocation = locationNodes.first {
            currentLocationIndicator.position = firstLocation.position
        }
        
        mapBackground.addChild(currentLocationIndicator)
    }
    
    private func setupCloseButton() {
        closeButton = CloseButton()
        let bgSize = CGSize(width: overlaySize.width * 0.9, height: overlaySize.height * 0.8)
        closeButton.position = CGPoint(
            x: bgSize.width/2 - 30,
            y: bgSize.height/2 - 30
        )
        closeButton.zPosition = 3
        closeButton.onTap = { [weak self] in
            self?.hudManager?.hide(.map)
        }
        
        mapBackground.addChild(closeButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let localPoint = convert(location, to: mapBackground)
        
        // Check location nodes (close button handles itself)
        for locationNode in locationNodes {
            if locationNode.contains(localPoint) && locationNode.isDiscovered {
                locationNode.handleTap()
                moveIndicatorTo(location: locationNode)
                return
            }
        }
    }
    
    private func moveIndicatorTo(location: LocationNode) {
        currentLocationIndicator.removeAllActions()
        
        let move = SKAction.move(to: location.position, duration: 0.3)
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        
        currentLocationIndicator.run(SKAction.group([
            move,
            SKAction.repeatForever(pulse)
        ]))
    }
}

class LocationNode: SKNode {
    let locationName: String
    var isDiscovered: Bool
    let nodeColor: UIColor
    private var icon: SKShapeNode!
    private var label: SKLabelNode!
    
    init(name: String, discovered: Bool, color: UIColor) {
        self.locationName = name
        self.isDiscovered = discovered
        self.nodeColor = color
        super.init()
        setupNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNode() {
        // Create circular icon instead of square
        icon = SKShapeNode(circleOfRadius: 30)
        icon.fillColor = isDiscovered ? nodeColor : .gray
        icon.strokeColor = isDiscovered ? .white : .gray
        icon.lineWidth = 3
        icon.alpha = isDiscovered ? 1.0 : 0.3
        
        if isDiscovered {
            icon.glowWidth = 2
        }
        
        addChild(icon)
        
        // Add inner decoration circle
        let innerCircle = SKShapeNode(circleOfRadius: 20)
        innerCircle.strokeColor = isDiscovered ? UIColor(white: 1.0, alpha: 0.3) : .clear
        innerCircle.lineWidth = 1
        innerCircle.fillColor = .clear
        icon.addChild(innerCircle)
        
        label = SKLabelNode(text: locationName)
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 14
        label.position = CGPoint(x: 0, y: -45)
        label.alpha = isDiscovered ? 1.0 : 0.3
        addChild(label)
    }
    
    func handleTap() {
        guard isDiscovered else { return }
        
        run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }
}