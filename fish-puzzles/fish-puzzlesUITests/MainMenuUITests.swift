//
//  MainMenuUITests.swift
//  fish-puzzlesUITests
//
//  UI Tests for Main Menu interactions
//

import XCTest

final class MainMenuUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testPlayButtonNavigatesToGame() throws {
        // Launch the application
        app.launch()
        
        // Wait for main menu to load and find the play button
        // Using otherElements because SpriteKit nodes appear as "other" elements
        let playButton = app.otherElements["playButton"]
        
        // Assert that the play button exists
        XCTAssertTrue(playButton.waitForExistence(timeout: 3), 
                     "Play button should be visible on main menu")
        
        // Tap the play button
        playButton.tap()
        
        // Wait for transition and verify we're in the game scene
        // We'll look for an element that indicates we're in Location1Scene
        let gameScene = app.otherElements["Location1Scene"]
        XCTAssertTrue(gameScene.waitForExistence(timeout: 3), 
                     "Should transition to Location1Scene after tapping Play")
    }
    
    @MainActor
    func testMainMenuHasTitle() throws {
        app.launch()
        
        // Check that the title "Fish Puzzles" is visible
        let title = app.staticTexts["Fish Puzzles"]
        XCTAssertTrue(title.waitForExistence(timeout: 3), 
                     "Main menu should display 'Fish Puzzles' title")
    }
}