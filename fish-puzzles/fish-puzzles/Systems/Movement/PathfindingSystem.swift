//
//  PathfindingSystem.swift
//  fish-puzzles
//
//  Tap-to-move pathfinding for point-and-click navigation
//

import Foundation
import SpriteKit
import GameplayKit

class PathfindingSystem {
    private var graph: GKGridGraph<GKGridGraphNode>?
    private let tileSize: Float = 32.0
    private var obstacles: Set<GKGridGraphNode> = []
    
    init(sceneSize: CGSize) {
        setupGraph(sceneSize: sceneSize)
    }
    
    private func setupGraph(sceneSize: CGSize) {
        let gridWidth = Int32(sceneSize.width / CGFloat(tileSize))
        let gridHeight = Int32(sceneSize.height / CGFloat(tileSize))
        
        graph = GKGridGraph(fromGridStartingAt: vector_int2(0, 0),
                           width: gridWidth,
                           height: gridHeight,
                           diagonalsAllowed: true,
                           nodeClass: GKGridGraphNode.self)
    }
    
    func addObstacle(at position: CGPoint, size: CGSize) {
        guard let graph = graph else { return }
        
        let startX = Int32(position.x / CGFloat(tileSize))
        let startY = Int32(position.y / CGFloat(tileSize))
        let width = Int32(size.width / CGFloat(tileSize))
        let height = Int32(size.height / CGFloat(tileSize))
        
        var nodesToRemove: [GKGridGraphNode] = []
        
        for x in startX..<(startX + width) {
            for y in startY..<(startY + height) {
                if let node = graph.node(atGridPosition: vector_int2(x, y)) {
                    nodesToRemove.append(node)
                    obstacles.insert(node)
                }
            }
        }
        
        graph.remove(nodesToRemove)
    }
    
    func removeObstacle(at position: CGPoint, size: CGSize) {
        guard let graph = graph else { return }
        
        let startX = Int32(position.x / CGFloat(tileSize))
        let startY = Int32(position.y / CGFloat(tileSize))
        let width = Int32(size.width / CGFloat(tileSize))
        let height = Int32(size.height / CGFloat(tileSize))
        
        var nodesToAdd: [GKGridGraphNode] = []
        
        for x in startX..<(startX + width) {
            for y in startY..<(startY + height) {
                let node = GKGridGraphNode(gridPosition: vector_int2(x, y))
                nodesToAdd.append(node)
                obstacles.remove(node)
            }
        }
        
        graph.add(nodesToAdd)
    }
    
    func findPath(from startPosition: CGPoint, to endPosition: CGPoint) -> [CGPoint]? {
        guard let graph = graph else { return nil }
        
        let startGrid = vector_int2(Int32(startPosition.x / CGFloat(tileSize)),
                                   Int32(startPosition.y / CGFloat(tileSize)))
        let endGrid = vector_int2(Int32(endPosition.x / CGFloat(tileSize)),
                                 Int32(endPosition.y / CGFloat(tileSize)))
        
        guard let startNode = graph.node(atGridPosition: startGrid),
              let endNode = graph.node(atGridPosition: endGrid) else {
            return nil
        }
        
        let path = graph.findPath(from: startNode, to: endNode) as? [GKGridGraphNode] ?? []
        
        return path.map { node in
            CGPoint(x: CGFloat(node.gridPosition.x) * CGFloat(tileSize) + CGFloat(tileSize/2),
                   y: CGFloat(node.gridPosition.y) * CGFloat(tileSize) + CGFloat(tileSize/2))
        }
    }
    
    func clearObstacles() {
        guard let graph = graph else { return }
        graph.add(Array(obstacles))
        obstacles.removeAll()
    }
}

class MovementComponent: Component {
    var speed: CGFloat = 200.0
    var currentPath: [CGPoint] = []
    var currentPathIndex: Int = 0
    var isMoving: Bool = false
    
    func moveTo(position: CGPoint, using pathfinding: PathfindingSystem) {
        guard let entity = entity,
              let node = entity.node else { return }
        
        if let path = pathfinding.findPath(from: node.position, to: position) {
            currentPath = path
            currentPathIndex = 0
            isMoving = true
        }
    }
    
    override func update(deltaTime: TimeInterval) {
        guard isMoving,
              currentPathIndex < currentPath.count,
              let entity = entity,
              let node = entity.node else {
            isMoving = false
            return
        }
        
        let targetPosition = currentPath[currentPathIndex]
        let direction = CGVector(dx: targetPosition.x - node.position.x,
                                dy: targetPosition.y - node.position.y)
        let distance = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
        
        if distance < 5.0 {
            currentPathIndex += 1
            if currentPathIndex >= currentPath.count {
                isMoving = false
                onReachedDestination()
            }
        } else {
            let normalizedDirection = CGVector(dx: direction.dx / distance,
                                              dy: direction.dy / distance)
            let movement = CGVector(dx: normalizedDirection.dx * speed * CGFloat(deltaTime),
                                   dy: normalizedDirection.dy * speed * CGFloat(deltaTime))
            
            node.position.x += movement.dx
            node.position.y += movement.dy
            
            onMoving(direction: normalizedDirection)
        }
    }
    
    func stopMovement() {
        isMoving = false
        currentPath.removeAll()
        currentPathIndex = 0
    }
    
    func onReachedDestination() {
        // Override in subclasses for arrival behavior
    }
    
    func onMoving(direction: CGVector) {
        // Override in subclasses for movement animation
    }
}