//
//  NavigationZoneComponent.swift
//  fish-puzzles
//
//  Defines navigation zones and approach points for entities
//

import Foundation
import CoreGraphics

class NavigationZoneComponent: Component {
    let approachPoint: CGPoint
    let interactionRadius: CGFloat
    let blockedAreas: [CGRect]
    let depthLayer: Int
    let allowSwimThrough: Bool
    
    init(approachPoint: CGPoint,
         interactionRadius: CGFloat = 40.0,
         blockedAreas: [CGRect] = [],
         depthLayer: Int = 0,
         allowSwimThrough: Bool = false) {
        self.approachPoint = approachPoint
        self.interactionRadius = interactionRadius
        self.blockedAreas = blockedAreas
        self.depthLayer = depthLayer
        self.allowSwimThrough = allowSwimThrough
        super.init()
    }
    
    func isPointBlocked(_ point: CGPoint) -> Bool {
        for area in blockedAreas {
            if area.contains(point) {
                return true
            }
        }
        return false
    }
    
    func isWithinInteractionRange(_ point: CGPoint) -> Bool {
        let distance = sqrt(pow(point.x - approachPoint.x, 2) + pow(point.y - approachPoint.y, 2))
        return distance <= interactionRadius
    }
    
    func getNearestAccessiblePoint(from point: CGPoint) -> CGPoint {
        if !isPointBlocked(point) {
            return point
        }
        
        let angle = atan2(point.y - approachPoint.y, point.x - approachPoint.x)
        let adjustedX = approachPoint.x + cos(angle) * (interactionRadius + 10)
        let adjustedY = approachPoint.y + sin(angle) * (interactionRadius + 10)
        
        return CGPoint(x: adjustedX, y: adjustedY)
    }
}

extension NavigationZoneComponent {
    static func chest(at position: CGPoint) -> NavigationZoneComponent {
        return NavigationZoneComponent(
            approachPoint: CGPoint(x: position.x, y: position.y - 50),
            interactionRadius: 40,
            blockedAreas: [CGRect(x: position.x - 30, y: position.y - 10, width: 60, height: 40)],
            depthLayer: 2
        )
    }
    
    static func bookshelf(at position: CGPoint) -> NavigationZoneComponent {
        return NavigationZoneComponent(
            approachPoint: CGPoint(x: position.x, y: position.y - 60),
            interactionRadius: 50,
            blockedAreas: [CGRect(x: position.x - 40, y: position.y - 20, width: 80, height: 100)],
            depthLayer: 3
        )
    }
    
    static func rock(at position: CGPoint, size: CGSize = CGSize(width: 60, height: 40)) -> NavigationZoneComponent {
        return NavigationZoneComponent(
            approachPoint: CGPoint(x: position.x, y: position.y - size.height/2 - 20),
            interactionRadius: 35,
            blockedAreas: [CGRect(x: position.x - size.width/2, 
                                 y: position.y - size.height/2, 
                                 width: size.width, 
                                 height: size.height)],
            depthLayer: 1
        )
    }
    
    static func npc(at position: CGPoint) -> NavigationZoneComponent {
        return NavigationZoneComponent(
            approachPoint: CGPoint(x: position.x, y: position.y - 40),
            interactionRadius: 50,
            blockedAreas: [],
            depthLayer: 2,
            allowSwimThrough: false
        )
    }
}