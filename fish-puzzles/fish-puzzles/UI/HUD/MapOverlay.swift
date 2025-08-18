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
        mapBackground.fillColor = UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.95)
        mapBackground.strokeColor = .white
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
            (name: "Coral Reef", position: CGPoint(x: -150, y: 50), discovered: true),
            (name: "Shipwreck", position: CGPoint(x: 0, y: 0), discovered: true),
            (name: "Deep Cave", position: CGPoint(x: 150, y: -50), discovered: false),
            (name: "Kelp Forest", position: CGPoint(x: -100, y: -100), discovered: false)
        ]
        
        for location in locations {
            let node = LocationNode(name: location.name, discovered: location.discovered)
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
                line.strokeColor = UIColor(white: 0.6, alpha: 0.5)
                line.lineWidth = 2
                line.zPosition = 1
                mapBackground.addChild(line)
            }
        }
    }
    
    private func setupCurrentLocationIndicator() {
        currentLocationIndicator = SKShapeNode(circleOfRadius: 15)
        currentLocationIndicator.fillColor = .yellow
        currentLocationIndicator.strokeColor = .clear
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
    private var icon: SKSpriteNode!
    private var label: SKLabelNode!
    
    init(name: String, discovered: Bool) {
        self.locationName = name
        self.isDiscovered = discovered
        super.init()
        setupNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNode() {
        let iconSize = CGSize(width: 60, height: 60)
        icon = SKSpriteNode(
            color: isDiscovered ? .cyan : .gray,
            size: iconSize
        )
        icon.alpha = isDiscovered ? 1.0 : 0.3
        addChild(icon)
        
        let shape = SKShapeNode(circleOfRadius: 30)
        shape.strokeColor = isDiscovered ? .white : .gray
        shape.lineWidth = 2
        icon.addChild(shape)
        
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