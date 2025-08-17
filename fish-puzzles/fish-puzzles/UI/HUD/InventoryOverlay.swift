//
//  InventoryOverlay.swift
//  fish-puzzles
//
//  Inventory management overlay
//

import SpriteKit

class InventoryOverlay: BaseOverlay {
    private var inventoryBackground: SKSpriteNode!
    private var itemSlots: [ItemSlot] = []
    private let slotsPerRow = 6
    private let maxSlots = 12
    private var closeButton: SKSpriteNode!
    
    init(size: CGSize) {
        super.init(layer: .inventory, size: size)
        self.isModal = true
        self.dimBackground = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupOverlay() {
        setupBackground()
        setupItemSlots()
        setupCloseButton()
    }
    
    private func setupBackground() {
        let bgSize = CGSize(width: overlaySize.width * 0.8, height: overlaySize.height * 0.7)
        inventoryBackground = SKSpriteNode(color: UIColor(white: 0.2, alpha: 0.95), size: bgSize)
        inventoryBackground.position = CGPoint.zero
        inventoryBackground.zPosition = 0
        
        let border = SKShapeNode(rectOf: bgSize, cornerRadius: 20)
        border.strokeColor = .cyan
        border.lineWidth = 3
        border.zPosition = 1
        inventoryBackground.addChild(border)
        
        addChild(inventoryBackground)
        
        let title = SKLabelNode(text: "Inventory")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 32
        title.position = CGPoint(x: 0, y: bgSize.height/2 - 40)
        title.zPosition = 2
        inventoryBackground.addChild(title)
    }
    
    private func setupItemSlots() {
        let slotSize: CGFloat = 80
        let spacing: CGFloat = 20
        let startX = -(CGFloat(slotsPerRow - 1) * (slotSize + spacing)) / 2
        let startY: CGFloat = 50
        
        for i in 0..<maxSlots {
            let row = i / slotsPerRow
            let col = i % slotsPerRow
            
            let slot = ItemSlot(size: CGSize(width: slotSize, height: slotSize))
            slot.position = CGPoint(
                x: startX + CGFloat(col) * (slotSize + spacing),
                y: startY - CGFloat(row) * (slotSize + spacing)
            )
            slot.zPosition = 2
            
            inventoryBackground.addChild(slot)
            itemSlots.append(slot)
        }
    }
    
    private func setupCloseButton() {
        let buttonSize = CGSize(width: 40, height: 40)
        closeButton = SKSpriteNode(color: .red, size: buttonSize)
        closeButton.position = CGPoint(
            x: inventoryBackground.size.width/2 - 30,
            y: inventoryBackground.size.height/2 - 30
        )
        closeButton.zPosition = 3
        closeButton.name = "closeButton"
        
        let xLabel = SKLabelNode(text: "✕")
        xLabel.fontSize = 24
        xLabel.fontName = "AvenirNext-Bold"
        xLabel.verticalAlignmentMode = .center
        closeButton.addChild(xLabel)
        
        inventoryBackground.addChild(closeButton)
    }
    
    override func handleTouch(at point: CGPoint) -> Bool {
        let localPoint = convert(point, to: inventoryBackground)
        
        if let touchedNode = inventoryBackground.atPoint(localPoint) as? SKSpriteNode {
            if touchedNode.name == "closeButton" || touchedNode.parent?.name == "closeButton" {
                if let hudManager = scene?.childNode(withName: "HUDContainer")?.parent as? BaseGameScene {
                }
                return true
            }
        }
        
        for slot in itemSlots {
            if slot.contains(localPoint) {
                slot.handleTap()
                return true
            }
        }
        
        return inventoryBackground.contains(localPoint)
    }
    
    func addItem(_ itemName: String, texture: SKTexture) {
        for slot in itemSlots {
            if slot.isEmpty {
                slot.setItem(name: itemName, texture: texture)
                break
            }
        }
    }
    
    func removeItem(_ itemName: String) {
        for slot in itemSlots {
            if slot.itemName == itemName {
                slot.clear()
                break
            }
        }
    }
}

class ItemSlot: SKSpriteNode {
    var itemName: String?
    var itemSprite: SKSpriteNode?
    var isEmpty: Bool { return itemName == nil }
    
    init(size: CGSize) {
        super.init(texture: nil, color: UIColor(white: 0.3, alpha: 0.8), size: size)
        setupSlot()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSlot() {
        let border = SKShapeNode(rectOf: size, cornerRadius: 10)
        border.strokeColor = .gray
        border.lineWidth = 2
        addChild(border)
    }
    
    func setItem(name: String, texture: SKTexture) {
        clear()
        
        itemName = name
        itemSprite = SKSpriteNode(texture: texture)
        itemSprite?.size = CGSize(width: size.width * 0.8, height: size.height * 0.8)
        itemSprite?.position = .zero
        
        if let sprite = itemSprite {
            addChild(sprite)
        }
    }
    
    func clear() {
        itemName = nil
        itemSprite?.removeFromParent()
        itemSprite = nil
    }
    
    func handleTap() {
        if !isEmpty {
            run(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }
    }
}