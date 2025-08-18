//
//  PersistentInventoryBar.swift
//  fish-puzzles
//
//  Always-visible inventory bar at bottom of screen
//

import SpriteKit

class PersistentInventoryBar: SKNode {
    static let maxVisibleSlots = 5
    static let slotSize = CGSize(width: 80, height: 80)
    static let barHeight: CGFloat = 100  // Matches SafeAreaManager.inventoryBarHeight
    
    private(set) var visibleSlots: [InventorySlot] = []
    private var selectedSlot: InventorySlot?
    private var overflowItems: [Item] = []
    private var moreButton: HUDButton?
    
    private let backgroundBar: SKShapeNode
    private let selectedIndicator: SKShapeNode
    private let slotSpacing: CGFloat = 10
    
    // Button containers
    private var leftButtonContainer: SKNode
    private var rightButtonContainer: SKNode
    private(set) var persistentButtons: [HUDButton] = []
    
    weak var hudManager: HUDManager?
    weak var inventoryManager: InventoryManager?
    
    var onItemSelected: ((Item?) -> Void)?
    var onItemDragStart: ((Item, CGPoint) -> Void)?
    var onItemDragEnd: ((Item, CGPoint) -> Void)?
    
    init(size: CGSize) {
        let barSize = CGSize(width: size.width, height: Self.barHeight)
        
        backgroundBar = SKShapeNode(rectOf: barSize, cornerRadius: 10)
        backgroundBar.fillColor = UIColor(white: 0.1, alpha: 0.9)
        backgroundBar.strokeColor = UIColor(white: 0.3, alpha: 0.8)
        backgroundBar.lineWidth = 2
        
        selectedIndicator = SKShapeNode(rectOf: CGSize(width: 90, height: 90), cornerRadius: 12)
        selectedIndicator.strokeColor = .systemYellow
        selectedIndicator.lineWidth = 3
        selectedIndicator.glowWidth = 5
        selectedIndicator.fillColor = .clear
        selectedIndicator.isHidden = true
        
        leftButtonContainer = SKNode()
        rightButtonContainer = SKNode()
        
        super.init()
        
        setupBar(size: size)
        setupSlots()
        setupMoreButton()
        setupButtonContainers()
        
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBar(size: CGSize) {
        // Position at bottom of screen, half the bar height up from the edge
        position = CGPoint(x: 0, y: -size.height/2 + Self.barHeight/2)
        zPosition = 50
        
        backgroundBar.position = CGPoint(x: 0, y: 0)
        backgroundBar.zPosition = 0
        addChild(backgroundBar)
        
        selectedIndicator.zPosition = 5
        addChild(selectedIndicator)
    }
    
    private func setupSlots() {
        let totalWidth = CGFloat(Self.maxVisibleSlots) * (Self.slotSize.width + slotSpacing) - slotSpacing
        let startX = -totalWidth / 2 + Self.slotSize.width / 2
        
        for i in 0..<Self.maxVisibleSlots {
            let slot = InventorySlot(size: Self.slotSize)
            slot.position = CGPoint(
                x: startX + CGFloat(i) * (Self.slotSize.width + slotSpacing),
                y: 0
            )
            slot.zPosition = 2
            slot.slotIndex = i
            
            backgroundBar.addChild(slot)
            visibleSlots.append(slot)
        }
    }
    
    private func setupMoreButton() {
        let buttonSize = CGSize(width: 60, height: 60)
        let lastSlot = visibleSlots.last!
        
        moreButton = HUDButton(type: .inventory, size: buttonSize)
        moreButton?.position = CGPoint(
            x: lastSlot.position.x + Self.slotSize.width/2 + slotSpacing + buttonSize.width/2,
            y: 0
        )
        moreButton?.zPosition = 2
        moreButton?.onTap = { [weak self] in
            self?.hudManager?.show(.inventory)
        }
        
        if let button = moreButton {
            backgroundBar.addChild(button)
        }
        
        updateMoreButton()
    }
    
    func updateInventory(items: [Item]) {
        for (index, slot) in visibleSlots.enumerated() {
            if index < items.count {
                let item = items[index]
                slot.setItem(item)
            } else {
                slot.clear()
            }
        }
        
        overflowItems = Array(items.dropFirst(Self.maxVisibleSlots))
        updateMoreButton()
    }
    
    func addItem(_ item: Item) {
        if let emptySlot = visibleSlots.first(where: { $0.isEmpty }) {
            emptySlot.setItem(item)
            animateItemAddition(to: emptySlot)
        } else {
            overflowItems.append(item)
            updateMoreButton()
        }
    }
    
    func removeItem(_ item: Item) {
        if let slot = visibleSlots.first(where: { $0.item?.id == item.id }) {
            slot.clear()
            
            if !overflowItems.isEmpty {
                let nextItem = overflowItems.removeFirst()
                slot.setItem(nextItem)
            }
            updateMoreButton()
        }
    }
    
    func selectItem(_ item: Item?) {
        selectedSlot?.setSelected(false)
        
        if let item = item,
           let slot = visibleSlots.first(where: { $0.item?.id == item.id }) {
            slot.setSelected(true)
            selectedSlot = slot
            
            selectedIndicator.position = convert(slot.position, from: backgroundBar)
            selectedIndicator.isHidden = false
            animateSelection()
            
            onItemSelected?(item)
        } else {
            selectedSlot = nil
            selectedIndicator.isHidden = true
            onItemSelected?(nil)
        }
    }
    
    private func setupButtonContainers() {
        // Left button container (for inventory, map buttons)
        leftButtonContainer.position = CGPoint(x: -backgroundBar.frame.width/2 + 100, y: 0)
        leftButtonContainer.zPosition = 3
        backgroundBar.addChild(leftButtonContainer)
        
        // Right button container (for settings, hint buttons)
        rightButtonContainer.position = CGPoint(x: backgroundBar.frame.width/2 - 100, y: 0)
        rightButtonContainer.zPosition = 3
        backgroundBar.addChild(rightButtonContainer)
    }
    
    func addPersistentButton(_ button: HUDButton, position: ButtonPosition) {
        // Remove button from any previous parent
        button.removeFromParent()
        
        switch position {
        case .left(let index):
            button.position = CGPoint(x: CGFloat(index) * 60, y: 0)
            leftButtonContainer.addChild(button)
        case .right(let index):
            button.position = CGPoint(x: CGFloat(-index) * 60, y: 0)
            rightButtonContainer.addChild(button)
        }
        
        button.zPosition = 4
        persistentButtons.append(button)
    }
    
    func removePersistentButton(_ button: HUDButton) {
        button.removeFromParent()
        persistentButtons.removeAll { $0 == button }
    }
    
    func clearPersistentButtons() {
        persistentButtons.forEach { $0.removeFromParent() }
        persistentButtons.removeAll()
    }
    
    enum ButtonPosition {
        case left(index: Int)
        case right(index: Int)
    }
    
    private func updateMoreButton() {
        let count = overflowItems.count
        moreButton?.isHidden = count == 0
        
        if count > 0 {
            if let label = moreButton?.children.first(where: { $0.name == "countLabel" }) as? SKLabelNode {
                label.text = "+\(count)"
            } else {
                let countLabel = SKLabelNode(text: "+\(count)")
                countLabel.name = "countLabel"
                countLabel.fontSize = 16
                countLabel.fontName = "AvenirNext-Bold"
                countLabel.position = CGPoint(x: 20, y: -20)
                countLabel.zPosition = 10
                moreButton?.addChild(countLabel)
            }
        }
    }
    
    private func animateItemAddition(to slot: InventorySlot) {
        slot.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        let sparkle = SKEmitterNode()
        sparkle.particleTexture = SKTexture(imageNamed: "spark")
        sparkle.particleBirthRate = 50
        sparkle.particleLifetime = 0.5
        sparkle.particleScale = 0.2
        sparkle.particleScaleSpeed = -0.4
        sparkle.particleColor = .systemYellow
        sparkle.position = slot.position
        sparkle.zPosition = 10
        
        backgroundBar.addChild(sparkle)
        
        sparkle.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    private func animateSelection() {
        selectedIndicator.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: backgroundBar)
        
        for slot in visibleSlots {
            if slot.contains(location) && !slot.isEmpty {
                handleSlotTouch(slot, touch: touch)
                return
            }
        }
    }
    
    private func handleSlotTouch(_ slot: InventorySlot, touch: UITouch) {
        guard let item = slot.item else { return }
        
        if selectedSlot == slot {
            selectItem(nil)
        } else {
            selectItem(item)
        }
        
        AudioManager.shared.playSFX("tap")
    }
    
    func handleDragStart(item: Item, at point: CGPoint) {
        onItemDragStart?(item, point)
    }
    
    func handleDragEnd(item: Item, at point: CGPoint) {
        onItemDragEnd?(item, point)
    }
    
    func highlightValidTarget(for item: Item) {
        visibleSlots.forEach { slot in
            if let slotItem = slot.item,
               inventoryManager?.canCombineItems(item, slotItem) == true {
                slot.showValidDropTarget()
            }
        }
    }
    
    func clearHighlights() {
        visibleSlots.forEach { $0.clearHighlight() }
    }
}

class InventorySlot: SKNode {
    private let slotSize: CGSize
    private let background: SKShapeNode
    private var itemSprite: SKSpriteNode?
    private var glowEffect: SKEffectNode?
    
    var item: Item?
    var isEmpty: Bool { return item == nil }
    var slotIndex: Int = 0
    
    private var isSelected = false
    private var isHighlighted = false
    
    init(size: CGSize) {
        self.slotSize = size
        
        background = SKShapeNode(rectOf: size, cornerRadius: 8)
        background.fillColor = UIColor(white: 0.2, alpha: 0.6)
        background.strokeColor = UIColor(white: 0.4, alpha: 0.8)
        background.lineWidth = 2
        
        super.init()
        
        addChild(background)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setItem(_ item: Item) {
        clear()
        
        self.item = item
        
        itemSprite = SKSpriteNode(imageNamed: item.imageName)
        itemSprite?.size = CGSize(
            width: slotSize.width * 0.7,
            height: slotSize.height * 0.7
        )
        itemSprite?.position = .zero
        itemSprite?.zPosition = 1
        
        if let sprite = itemSprite {
            addChild(sprite)
        }
    }
    
    func clear() {
        item = nil
        itemSprite?.removeFromParent()
        itemSprite = nil
        clearHighlight()
    }
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
        
        if selected {
            background.strokeColor = .systemYellow
            background.glowWidth = 5
            itemSprite?.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ])))
        } else {
            background.strokeColor = UIColor(white: 0.4, alpha: 0.8)
            background.glowWidth = 0
            itemSprite?.removeAllActions()
            itemSprite?.setScale(1.0)
        }
    }
    
    func showValidDropTarget() {
        isHighlighted = true
        background.strokeColor = .systemGreen
        background.glowWidth = 8
        
        run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])), withKey: "validTarget")
    }
    
    func showInvalidDropTarget() {
        background.strokeColor = .systemRed
        
        run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }
    
    func clearHighlight() {
        isHighlighted = false
        removeAction(forKey: "validTarget")
        setScale(1.0)
        
        if !isSelected {
            background.strokeColor = UIColor(white: 0.4, alpha: 0.8)
            background.glowWidth = 0
        }
    }
    
    func animatePickup() {
        run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 0, duration: 0.2)
        ]))
    }
    
    func animatePlace() {
        setScale(0)
        run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }
}