//
//  SafeAreaManager.swift
//  fish-puzzles
//
//  Manages safe areas for gameplay content above UI elements
//

import UIKit
import SpriteKit

class SafeAreaManager {
    static let shared = SafeAreaManager()
    
    // UI element heights
    static let inventoryBarHeight: CGFloat = 100
    static let inventoryBarPadding: CGFloat = 10  // Extra padding above inventory
    
    private init() {}
    
    /// Calculate the safe gameplay area for a given scene size
    func gameplayArea(for sceneSize: CGSize) -> CGRect {
        let deviceSafeInsets = getDeviceSafeInsets()
        
        // Calculate bottom offset (inventory bar + safe area)
        let bottomOffset = Self.inventoryBarHeight + Self.inventoryBarPadding + deviceSafeInsets.bottom
        
        // Calculate top offset (status bar + notch if present)
        let topOffset = deviceSafeInsets.top
        
        // Calculate horizontal offsets (for devices with side safe areas)
        let leftOffset = deviceSafeInsets.left
        let rightOffset = deviceSafeInsets.right
        
        return CGRect(
            x: leftOffset,
            y: bottomOffset,
            width: sceneSize.width - leftOffset - rightOffset,
            height: sceneSize.height - bottomOffset - topOffset
        )
    }
    
    /// Get the center point of the safe gameplay area
    func gameplayCenter(for sceneSize: CGSize) -> CGPoint {
        let safeArea = gameplayArea(for: sceneSize)
        return CGPoint(
            x: safeArea.midX,
            y: safeArea.midY
        )
    }
    
    /// Convert a normalized position (0-1) to actual position within safe area
    func positionInSafeArea(normalized: CGPoint, sceneSize: CGSize) -> CGPoint {
        let safeArea = gameplayArea(for: sceneSize)
        return CGPoint(
            x: safeArea.minX + (normalized.x * safeArea.width),
            y: safeArea.minY + (normalized.y * safeArea.height)
        )
    }
    
    /// Check if a point is within the safe gameplay area
    func isInSafeArea(point: CGPoint, sceneSize: CGSize) -> Bool {
        return gameplayArea(for: sceneSize).contains(point)
    }
    
    /// Get the maximum Y position for ground-level objects
    func groundLevel(for sceneSize: CGSize) -> CGFloat {
        return gameplayArea(for: sceneSize).minY
    }
    
    /// Get the maximum Y position for sky-level objects
    func skyLevel(for sceneSize: CGSize) -> CGFloat {
        return gameplayArea(for: sceneSize).maxY
    }
    
    private func getDeviceSafeInsets() -> UIEdgeInsets {
        // Get the current window's safe area insets
        if let window = UIApplication.shared.windows.first {
            return window.safeAreaInsets
        }
        
        // Fallback for standard devices
        return UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: 0,
            right: 0
        )
    }
    
    /// Create debug visualization of safe areas
    func createDebugOverlay(for scene: SKScene) -> SKNode {
        let debugNode = SKNode()
        debugNode.name = "safeAreaDebug"
        
        let sceneSize = scene.size
        let safeArea = gameplayArea(for: sceneSize)
        
        // Create inventory bar exclusion zone (red)
        let inventoryZone = SKShapeNode(rect: CGRect(
            x: 0,
            y: 0,
            width: sceneSize.width,
            height: Self.inventoryBarHeight
        ))
        inventoryZone.fillColor = .red
        inventoryZone.alpha = 0.2
        inventoryZone.strokeColor = .red
        inventoryZone.lineWidth = 2
        inventoryZone.zPosition = 999
        debugNode.addChild(inventoryZone)
        
        // Create safe gameplay area (green)
        let safeZone = SKShapeNode(rect: safeArea)
        safeZone.fillColor = .clear
        safeZone.strokeColor = .green
        safeZone.lineWidth = 3
        safeZone.glowWidth = 2
        safeZone.zPosition = 999
        debugNode.addChild(safeZone)
        
        // Add center crosshair
        let centerX = safeArea.midX
        let centerY = safeArea.midY
        
        let horizontalLine = SKShapeNode(rect: CGRect(
            x: centerX - 20,
            y: centerY - 1,
            width: 40,
            height: 2
        ))
        horizontalLine.fillColor = .yellow
        horizontalLine.zPosition = 1000
        debugNode.addChild(horizontalLine)
        
        let verticalLine = SKShapeNode(rect: CGRect(
            x: centerX - 1,
            y: centerY - 20,
            width: 2,
            height: 40
        ))
        verticalLine.fillColor = .yellow
        verticalLine.zPosition = 1000
        debugNode.addChild(verticalLine)
        
        // Add labels
        let inventoryLabel = SKLabelNode(text: "INVENTORY ZONE")
        inventoryLabel.fontSize = 14
        inventoryLabel.fontName = "AvenirNext-Bold"
        inventoryLabel.fontColor = .red
        inventoryLabel.position = CGPoint(x: sceneSize.width / 2, y: Self.inventoryBarHeight / 2)
        inventoryLabel.zPosition = 1000
        debugNode.addChild(inventoryLabel)
        
        let safeLabel = SKLabelNode(text: "SAFE GAMEPLAY AREA")
        safeLabel.fontSize = 16
        safeLabel.fontName = "AvenirNext-Bold"
        safeLabel.fontColor = .green
        safeLabel.position = CGPoint(x: centerX, y: safeArea.maxY - 20)
        safeLabel.zPosition = 1000
        debugNode.addChild(safeLabel)
        
        return debugNode
    }
}

// Extension for easy access from scenes
extension SKScene {
    var safeGameplayArea: CGRect {
        return SafeAreaManager.shared.gameplayArea(for: self.size)
    }
    
    var safeGameplayCenter: CGPoint {
        return SafeAreaManager.shared.gameplayCenter(for: self.size)
    }
    
    func safePosition(normalizedX: CGFloat, normalizedY: CGFloat) -> CGPoint {
        return SafeAreaManager.shared.positionInSafeArea(
            normalized: CGPoint(x: normalizedX, y: normalizedY),
            sceneSize: self.size
        )
    }
}