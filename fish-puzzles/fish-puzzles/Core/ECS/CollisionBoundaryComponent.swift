//
//  CollisionBoundaryComponent.swift
//  fish-puzzles
//
//  Defines collision boundaries for entities
//

import Foundation
import CoreGraphics

enum BoundaryType {
    case solid
    case semiSolid
    case trigger
}

class CollisionBoundaryComponent: Component {
    let boundary: CGPath
    let type: BoundaryType
    let allowsPathfinding: Bool
    private let boundingBox: CGRect
    
    init(boundary: CGPath, type: BoundaryType = .solid, allowsPathfinding: Bool = true) {
        self.boundary = boundary
        self.type = type
        self.allowsPathfinding = allowsPathfinding
        self.boundingBox = boundary.boundingBox
        super.init()
    }
    
    convenience init(rect: CGRect, type: BoundaryType = .solid, allowsPathfinding: Bool = true) {
        let path = CGMutablePath()
        path.addRect(rect)
        self.init(boundary: path, type: type, allowsPathfinding: allowsPathfinding)
    }
    
    convenience init(circle center: CGPoint, radius: CGFloat, type: BoundaryType = .solid) {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: center.x - radius, 
                                   y: center.y - radius, 
                                   width: radius * 2, 
                                   height: radius * 2))
        self.init(boundary: path, type: type)
    }
    
    func contains(_ point: CGPoint) -> Bool {
        if !boundingBox.contains(point) {
            return false
        }
        return boundary.contains(point, using: .evenOdd, transform: .identity)
    }
    
    func intersects(with otherBoundary: CollisionBoundaryComponent) -> Bool {
        if !boundingBox.intersects(otherBoundary.boundingBox) {
            return false
        }
        
        return checkPathIntersection(boundary, otherBoundary.boundary)
    }
    
    func intersects(with rect: CGRect) -> Bool {
        if !boundingBox.intersects(rect) {
            return false
        }
        
        let rectPath = CGMutablePath()
        rectPath.addRect(rect)
        return checkPathIntersection(boundary, rectPath)
    }
    
    private func checkPathIntersection(_ path1: CGPath, _ path2: CGPath) -> Bool {
        var intersects = false
        
        path1.applyWithBlock { element in
            let points = element.pointee.points
            
            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint:
                if element.pointee.type == .moveToPoint || element.pointee.type == .addLineToPoint {
                    let point = points[0]
                    if path2.contains(point, using: .evenOdd, transform: .identity) {
                        intersects = true
                    }
                }
            case .addQuadCurveToPoint:
                let point = points[1]
                if path2.contains(point, using: .evenOdd, transform: .identity) {
                    intersects = true
                }
            case .addCurveToPoint:
                let point = points[2]
                if path2.contains(point, using: .evenOdd, transform: .identity) {
                    intersects = true
                }
            default:
                break
            }
        }
        
        return intersects
    }
    
    func getBlockedDirection(from point: CGPoint, moving direction: CGVector) -> CGVector? {
        guard type == .solid else { return nil }
        
        let testPoint = CGPoint(x: point.x + direction.dx * 5, 
                               y: point.y + direction.dy * 5)
        
        if contains(testPoint) {
            let normal = calculateNormal(at: point)
            return normal
        }
        
        return nil
    }
    
    private func calculateNormal(at point: CGPoint) -> CGVector {
        let testDistance: CGFloat = 1.0
        var normalX: CGFloat = 0
        var normalY: CGFloat = 0
        var count = 0
        
        for angle in stride(from: 0, to: 360, by: 45) {
            let radians = CGFloat(angle) * .pi / 180
            let testPoint = CGPoint(x: point.x + cos(radians) * testDistance,
                                   y: point.y + sin(radians) * testDistance)
            
            if !contains(testPoint) {
                normalX += cos(radians)
                normalY += sin(radians)
                count += 1
            }
        }
        
        if count > 0 {
            normalX /= CGFloat(count)
            normalY /= CGFloat(count)
            
            let length = sqrt(normalX * normalX + normalY * normalY)
            if length > 0 {
                normalX /= length
                normalY /= length
            }
        }
        
        return CGVector(dx: normalX, dy: normalY)
    }
}

extension CollisionBoundaryComponent {
    static func wall(from start: CGPoint, to end: CGPoint, thickness: CGFloat = 10) -> CollisionBoundaryComponent {
        let path = CGMutablePath()
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        let perpX = -dy / length * thickness / 2
        let perpY = dx / length * thickness / 2
        
        path.move(to: CGPoint(x: start.x - perpX, y: start.y - perpY))
        path.addLine(to: CGPoint(x: end.x - perpX, y: end.y - perpY))
        path.addLine(to: CGPoint(x: end.x + perpX, y: end.y + perpY))
        path.addLine(to: CGPoint(x: start.x + perpX, y: start.y + perpY))
        path.closeSubpath()
        
        return CollisionBoundaryComponent(boundary: path, type: .solid)
    }
    
    static func trigger(rect: CGRect, allowsPathfinding: Bool = false) -> CollisionBoundaryComponent {
        return CollisionBoundaryComponent(rect: rect, type: .trigger, allowsPathfinding: allowsPathfinding)
    }
}