//
//  GameViewController.swift
//  fish-puzzles
//
//  Created by Jay Kerschner on 8/16/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let view = self.view as? SKView else { return }
        
        // Initialize the game engine with the view
        GameEngine.shared.start(with: view)
        
        // This will load MainMenuScene, which has a Play button
        // that transitions to Location1Scene
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
