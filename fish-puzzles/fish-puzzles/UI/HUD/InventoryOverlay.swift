//
//  InventoryOverlay.swift
//  fish-puzzles
//
//  Inventory management overlay
//

import SpriteKit

class InventoryOverlay: BaseOverlay {
    private var inventoryBackground: SKShapeNode!
    private var itemSlots: [ItemSlot] = []
    private let slotsPerRow = 6
    private let maxSlots = 12
    private var closeButton: CloseButton!
    
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
        inventoryBackground = SKShapeNode(rectOf: bgSize, cornerRadius: 20)
        inventoryBackground.fillColor = UIColor(white: 0.2, alpha: 0.95)
        inventoryBackground.strokeColor = .cyan
        inventoryBackground.lineWidth = 3
        inventoryBackground.position = CGPoint.zero
        inventoryBackground.zPosition = 0
        
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
        closeButton = CloseButton()
        let bgSize = CGSize(width: overlaySize.width * 0.8, height: overlaySize.height * 0.7)
        closeButton.position = CGPoint(
            x: bgSize.width/2 - 30,
            y: bgSize.height/2 - 30
        )
        closeButton.zPosition = 3
        closeButton.onTap = { [weak self] in
            self?.hudManager?.hide(.inventory)
        }
        
        inventoryBackground.addChild(closeButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let localPoint = convert(location, to: inventoryBackground)
        
        // Check item slots (close button handles itself via isUserInteractionEnabled)
        for slot in itemSlots {
            let slotPoint = inventoryBackground.convert(localPoint, to: slot)
            if slot.background.contains(slotPoint) {
                slot.handleTap()
                return
            }
        }
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

class ItemSlot: SKNode {
    var itemName: String?
    var itemSprite: SKSpriteNode?
    var isEmpty: Bool { return itemName == nil }
    private let slotSize: CGSize
    var background: SKShapeNode!
    
    init(size: CGSize) {
        self.slotSize = size
        super.init()
        setupSlot()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSlot() {
        background = SKShapeNode(rectOf: slotSize, cornerRadius: 10)
        background.fillColor = UIColor(white: 0.3, alpha: 0.8)
        background.strokeColor = .gray
        background.lineWidth = 2
        addChild(background)
    }
    
    func setItem(name: String, texture: SKTexture) {
        clear()
        
        itemName = name
        itemSprite = SKSpriteNode(texture: texture)
        itemSprite?.size = CGSize(width: slotSize.width * 0.8, height: slotSize.height * 0.8)
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