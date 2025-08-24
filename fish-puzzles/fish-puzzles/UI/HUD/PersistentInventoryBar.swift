//
//  PersistentInventoryBar.swift
//  fish-puzzles
//
//  Always-visible inventory bar at bottom of screen
//

import SpriteKit

class PersistentInventoryBar: SKNode {
    // Max visible slots adapts to width; keep static so other systems can reference it
    static var maxVisibleSlots = 5
    // Slot size adapts to bar height
    private(set) var slotSize = CGSize(width: 80, height: 80)
    // Instance bar height (synced with SafeAreaManager)
    private(set) var barHeight: CGFloat = 100  // Matches SafeAreaManager.inventoryBarHeight
    
    private(set) var visibleSlots: [InventorySlot] = []
    private var selectedSlot: InventorySlot?
    private var overflowItems: [Item] = []
    private var moreButton: HUDButton?
    
    private let backgroundBar: SKSpriteNode
    private let backgroundBorder: SKShapeNode
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
    
    private var lastKnownSceneSize: CGSize

    init(size: CGSize) {
        // Calculate responsive bar metrics up front
        self.lastKnownSceneSize = size
        self.barHeight = Self.preferredBarHeight(for: size)
        SafeAreaManager.setInventoryBarHeight(self.barHeight)
        let barSize = CGSize(width: size.width, height: self.barHeight)
        
        // Create a completely opaque black background using Core Graphics
        UIGraphicsBeginImageContextWithOptions(barSize, true, 0)  // 'true' makes it opaque
        let context = UIGraphicsGetCurrentContext()!
        // Fill with black
        context.setFillColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: barSize))
        let blackImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Create the texture and sprite
        let blackTexture = SKTexture(image: blackImage)
        blackTexture.filteringMode = .nearest  // No filtering
        
        // Use texture-based sprite with no possibility of color modification
        backgroundBar = SKSpriteNode(texture: blackTexture)
        backgroundBar.size = barSize
        backgroundBar.blendMode = .replace  // Replace mode ignores any underlying colors
        backgroundBar.color = .white  // White color means no tinting
        backgroundBar.colorBlendFactor = 0  // Absolutely no color blending
        
        // Add border as separate shape node
        backgroundBorder = SKShapeNode(rectOf: barSize, cornerRadius: 10)
        backgroundBorder.fillColor = .clear
        backgroundBorder.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        backgroundBorder.lineWidth = 2
        
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
        setupButtonContainers()
        relayout(for: size)
        
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBar(size: CGSize) {
        // Position at bottom of screen (now relative to scene, not container)
        position = CGPoint(x: size.width/2, y: barHeight/2)
        zPosition = 5000  // Extremely high z-position
        
        // Ensure this node is fully opaque and interactive
        self.isUserInteractionEnabled = true
        self.alpha = 1.0
        
        backgroundBar.position = CGPoint(x: 0, y: 0)
        backgroundBar.zPosition = -1  // Below other elements in this node
        backgroundBar.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(backgroundBar)
        
        // Add an additional opaque background layer for extra insurance
        let solidBackground = SKSpriteNode(color: .black, size: backgroundBar.size)
        solidBackground.position = CGPoint(x: 0, y: 0)
        solidBackground.zPosition = -2
        solidBackground.blendMode = .replace
        solidBackground.alpha = 1.0
        addChild(solidBackground)
        
        backgroundBorder.position = CGPoint(x: 0, y: 0)
        backgroundBorder.zPosition = 1  // Border on top of background
        addChild(backgroundBorder)
        
        selectedIndicator.zPosition = 5
        addChild(selectedIndicator)
    }
    
    private func setupMoreButtonIfNeeded(buttonSize: CGSize, at positionX: CGFloat) {
        if moreButton == nil {
            moreButton = HUDButton(type: .inventory, size: buttonSize)
            moreButton?.zPosition = 2
            moreButton?.onTap = { [weak self] in
                self?.hudManager?.show(.inventory)
            }
            if let button = moreButton { addChild(button) }
        }
        moreButton?.position = CGPoint(x: positionX, y: 0)
        moreButton?.resize(to: buttonSize)
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
            
            selectedIndicator.position = slot.position
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
        leftButtonContainer.position = CGPoint(x: -backgroundBar.size.width/2 + 100, y: 0)
        leftButtonContainer.zPosition = 3
        addChild(leftButtonContainer)
        
        // Right button container (for settings, hint buttons)
        rightButtonContainer.position = CGPoint(x: backgroundBar.size.width/2 - 100, y: 0)
        rightButtonContainer.zPosition = 3
        addChild(rightButtonContainer)
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
        // Relayout to account for new buttons
        relayout(for: lastKnownSceneSize)
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
        sparkle.particleTexture = AssetManager.shared.texture(named: "spark")
        sparkle.particleBirthRate = 50
        sparkle.particleLifetime = 0.5
        sparkle.particleScale = 0.2
        sparkle.particleScaleSpeed = -0.4
        sparkle.particleColor = .systemYellow
        sparkle.position = slot.position
        sparkle.zPosition = 10
        
        addChild(sparkle)
        
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
        let location = touch.location(in: self)
        
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
    private(set) var slotSize: CGSize
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
        itemSprite?.size = CGSize(width: slotSize.width * 0.7, height: slotSize.height * 0.7)
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

    func resize(to size: CGSize) {
        slotSize = size
        background.path = CGPath(roundedRect: CGRect(origin: .zero, size: size).offsetBy(dx: -size.width/2, dy: -size.height/2), cornerWidth: 8, cornerHeight: 8, transform: nil)
        if let sprite = itemSprite {
            sprite.size = CGSize(width: size.width * 0.7, height: size.height * 0.7)
        }
    }
}

// MARK: - Responsive Layout
extension PersistentInventoryBar {
    /// Calculate a reasonable bar height for the given scene size
    static func preferredBarHeight(for size: CGSize) -> CGFloat {
        // 12% of height on phones; clamp to keep it usable across devices
        let target = size.height * 0.12
        return max(72, min(target, 140))
    }

    /// Recompute sizes, counts, and positions based on the new scene size
    func resize(to size: CGSize) {
        lastKnownSceneSize = size

        // Update bar height and notify safe area manager
        barHeight = Self.preferredBarHeight(for: size)
        SafeAreaManager.setInventoryBarHeight(barHeight)

        // Resize background and border
        let newBarSize = CGSize(width: size.width, height: barHeight)
        backgroundBar.size = newBarSize
        backgroundBorder.path = CGPath(roundedRect: CGRect(origin: .zero, size: newBarSize).offsetBy(dx: -newBarSize.width/2, dy: -newBarSize.height/2), cornerWidth: 10, cornerHeight: 10, transform: nil)

        // Reposition node at the bottom center
        position = CGPoint(x: size.width/2, y: barHeight/2)

        // Layout slots, buttons, and more button
        relayout(for: size)
        // Refresh items into resized slots
        updateInventory(items: InventoryManager.shared.items)
    }

    private func relayout(for size: CGSize) {
        // Compute sizes
        slotSize = CGSize(width: barHeight * 0.8, height: barHeight * 0.8)
        let buttonSize = CGSize(width: barHeight * 0.6, height: barHeight * 0.6)
        let sideMargin: CGFloat = 12
        let buttonSpacing: CGFloat = 8

        // Update selection indicator to track new slot size
        let indicatorSize = CGSize(width: slotSize.width + 10, height: slotSize.height + 10)
        selectedIndicator.path = CGPath(roundedRect: CGRect(origin: .zero, size: indicatorSize).offsetBy(dx: -indicatorSize.width/2, dy: -indicatorSize.height/2), cornerWidth: 12, cornerHeight: 12, transform: nil)

        // Update button containers near edges
        leftButtonContainer.position = CGPoint(x: -backgroundBar.size.width/2 + sideMargin + buttonSize.width/2, y: 0)
        rightButtonContainer.position = CGPoint(x: backgroundBar.size.width/2 - sideMargin - buttonSize.width/2, y: 0)
        // Resize existing buttons to match new button size
        for (i, btn) in leftButtonContainer.children.enumerated() {
            (btn as? HUDButton)?.resize(to: buttonSize)
            btn.position = CGPoint(x: CGFloat(i) * (buttonSize.width + buttonSpacing), y: 0)
        }
        for (i, btn) in rightButtonContainer.children.enumerated() {
            (btn as? HUDButton)?.resize(to: buttonSize)
            btn.position = CGPoint(x: CGFloat(-i) * (buttonSize.width + buttonSpacing), y: 0)
        }

        // Calculate available width for slots between the button containers
        let leftCount = CGFloat(leftButtonContainer.children.count)
        let leftGapCount = max(0, leftButtonContainer.children.count - 1)
        let leftGapsWidth = CGFloat(leftGapCount) * buttonSpacing
        let leftWidth = (leftCount * buttonSize.width) + leftGapsWidth + sideMargin

        let rightCount = CGFloat(rightButtonContainer.children.count)
        let rightGapCount = max(0, rightButtonContainer.children.count - 1)
        let rightGapsWidth = CGFloat(rightGapCount) * buttonSpacing
        let rightWidth = (rightCount * buttonSize.width) + rightGapsWidth + sideMargin

        let centerWidth = backgroundBar.size.width - leftWidth - rightWidth

        // Determine how many slots fit (reserve space for the more button)
        let perSlot = slotSize.width + slotSpacing
        let reservedForMore = buttonSize.width + buttonSpacing
        let slotsFitFloat = (centerWidth - reservedForMore + slotSpacing) / perSlot
        let maxSlotsFitting = Int(slotsFitFloat.rounded(.down))
        let clampedSlots = max(3, min(8, maxSlotsFitting))
        Self.maxVisibleSlots = clampedSlots

        // Adjust visible slot nodes to match the count
        if visibleSlots.count != clampedSlots {
            // Remove old slots
            visibleSlots.forEach { $0.removeFromParent() }
            visibleSlots.removeAll()
            // Create new slots
            for i in 0..<clampedSlots {
                let slot = InventorySlot(size: slotSize)
                slot.zPosition = 2
                slot.slotIndex = i
                addChild(slot)
                visibleSlots.append(slot)
            }
        } else {
            // Resize existing slot visuals
            for slot in visibleSlots {
                slot.resize(to: slotSize)
            }
        }

        // Lay out slots centered in the remaining space between button groups
        let totalSlotsWidth = CGFloat(clampedSlots) * (slotSize.width + slotSpacing) - slotSpacing
        let leftEdge = -backgroundBar.size.width/2 + leftWidth
        let startX = leftEdge + (centerWidth - reservedForMore - totalSlotsWidth)/2 + slotSize.width/2
        for (i, slot) in visibleSlots.enumerated() {
            slot.position = CGPoint(
                x: startX + CGFloat(i) * (slotSize.width + slotSpacing),
                y: 0
            )
        }

        // Place the more button at the end of the slots area
        let moreX = startX + CGFloat(clampedSlots) * (slotSize.width + slotSpacing) - slotSpacing + buttonSpacing + buttonSize.width/2
        setupMoreButtonIfNeeded(buttonSize: buttonSize, at: moreX)
    }
}
