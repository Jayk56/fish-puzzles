//
//  ParentalGate.swift
//  fish-puzzles
//
//  COPPA-compliant parental gate system
//

import UIKit
import SpriteKit

protocol ParentalGateDelegate: AnyObject {
    func parentalGateDidSucceed()
    func parentalGateDidFail()
    func parentalGateDidCancel()
}

class ParentalGate {
    static let shared = ParentalGate()
    weak var delegate: ParentalGateDelegate?
    
    private var currentChallenge: MathChallenge?
    private var alertController: UIAlertController?
    
    private init() {}
    
    struct MathChallenge {
        let question: String
        let answer: Int
        
        static func generate() -> MathChallenge {
            let a = Int.random(in: 11...20)
            let b = Int.random(in: 11...20)
            let operations = ["+", "-", "*"]
            let operation = operations.randomElement()!
            
            var answer: Int
            var question: String
            
            switch operation {
            case "+":
                answer = a + b
                question = "What is \(a) + \(b)?"
            case "-":
                answer = a - b
                question = "What is \(a) - \(b)?"
            case "*":
                answer = a * b
                question = "What is \(a) × \(b)?"
            default:
                answer = a + b
                question = "What is \(a) + \(b)?"
            }
            
            return MathChallenge(question: question, answer: answer)
        }
    }
    
    func present(from viewController: UIViewController, 
                 reason: String = "This action requires parental permission") {
        currentChallenge = MathChallenge.generate()
        
        alertController = UIAlertController(
            title: "Parental Verification Required",
            message: "\(reason)\n\nPlease solve: \(currentChallenge!.question)",
            preferredStyle: .alert
        )
        
        alertController?.addTextField { textField in
            textField.placeholder = "Enter answer"
            textField.keyboardType = .numberPad
            textField.autocorrectionType = .no
        }
        
        let verifyAction = UIAlertAction(title: "Verify", style: .default) { [weak self] _ in
            self?.verifyAnswer()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.parentalGateDidCancel()
        }
        
        alertController?.addAction(verifyAction)
        alertController?.addAction(cancelAction)
        
        viewController.present(alertController!, animated: true)
    }
    
    private func verifyAnswer() {
        guard let challenge = currentChallenge,
              let textField = alertController?.textFields?.first,
              let answerText = textField.text,
              let answer = Int(answerText) else {
            delegate?.parentalGateDidFail()
            return
        }
        
        if answer == challenge.answer {
            delegate?.parentalGateDidSucceed()
        } else {
            delegate?.parentalGateDidFail()
        }
        
        currentChallenge = nil
        alertController = nil
    }
}

class ParentalGateScene: SKScene {
    var onSuccess: (() -> Void)?
    var onCancel: (() -> Void)?
    
    private var questionLabel: SKLabelNode!
    private var inputNodes: [SKLabelNode] = []
    private var currentInput: String = ""
    private var challenge: ParentalGate.MathChallenge!
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
        generateChallenge()
    }
    
    private func setupScene() {
        backgroundColor = SKColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        
        // Title
        let titleLabel = SKLabelNode(text: "Ask a Parent")
        titleLabel.fontName = "Avenir-Heavy"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY + 150)
        addChild(titleLabel)
        
        // Question
        questionLabel = SKLabelNode(text: "")
        questionLabel.fontName = "Avenir-Medium"
        questionLabel.fontSize = 24
        questionLabel.fontColor = .black
        questionLabel.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        addChild(questionLabel)
        
        // Number pad
        createNumberPad()
        
        // Buttons
        createButtons()
    }
    
    private func generateChallenge() {
        challenge = ParentalGate.MathChallenge.generate()
        questionLabel.text = challenge.question
    }
    
    private func createNumberPad() {
        let buttonSize = CGSize(width: 60, height: 60)
        let spacing: CGFloat = 10
        let startX = frame.midX - (buttonSize.width + spacing) * 1.5
        let startY = frame.midY - 50
        
        for i in 1...9 {
            let row = (i - 1) / 3
            let col = (i - 1) % 3
            
            let x = startX + CGFloat(col) * (buttonSize.width + spacing)
            let y = startY - CGFloat(row) * (buttonSize.height + spacing)
            
            createNumberButton(number: i, at: CGPoint(x: x, y: y), size: buttonSize)
        }
        
        // Zero button
        createNumberButton(number: 0, 
                         at: CGPoint(x: frame.midX, y: startY - 3 * (buttonSize.height + spacing)),
                         size: buttonSize)
        
        // Clear button
        let clearButton = createButton(text: "Clear",
                                      at: CGPoint(x: startX, y: startY - 3 * (buttonSize.height + spacing)),
                                      size: buttonSize)
        clearButton.name = "clear"
    }
    
    private func createNumberButton(number: Int, at position: CGPoint, size: CGSize) {
        let button = SKShapeNode(rectOf: size, cornerRadius: 8)
        button.fillColor = .white
        button.strokeColor = .darkGray
        button.position = position
        button.name = "number_\(number)"
        
        let label = SKLabelNode(text: "\(number)")
        label.fontName = "Avenir-Medium"
        label.fontSize = 24
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        addChild(button)
    }
    
    private func createButton(text: String, at position: CGPoint, size: CGSize) -> SKShapeNode {
        let button = SKShapeNode(rectOf: size, cornerRadius: 8)
        button.fillColor = .systemBlue
        button.strokeColor = .darkGray
        button.position = position
        
        let label = SKLabelNode(text: text)
        label.fontName = "Avenir-Medium"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        addChild(button)
        return button
    }
    
    private func createButtons() {
        // Submit button
        let submitButton = createButton(text: "Submit",
                                      at: CGPoint(x: frame.midX - 70, y: frame.midY - 250),
                                      size: CGSize(width: 120, height: 50))
        submitButton.name = "submit"
        
        // Cancel button
        let cancelButton = createButton(text: "Cancel",
                                      at: CGPoint(x: frame.midX + 70, y: frame.midY - 250),
                                      size: CGSize(width: 120, height: 50))
        cancelButton.name = "cancel"
        cancelButton.fillColor = .systemRed
        
        // Input display
        let inputDisplay = SKShapeNode(rectOf: CGSize(width: 200, height: 40), cornerRadius: 4)
        inputDisplay.fillColor = .white
        inputDisplay.strokeColor = .darkGray
        inputDisplay.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(inputDisplay)
        
        let inputLabel = SKLabelNode(text: "")
        inputLabel.fontName = "Avenir-Medium"
        inputLabel.fontSize = 20
        inputLabel.fontColor = .black
        inputLabel.verticalAlignmentMode = .center
        inputLabel.name = "input_display"
        inputDisplay.addChild(inputLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        if let name = node.name {
            if name.starts(with: "number_") {
                let number = String(name.dropFirst(7))
                currentInput += number
                updateInputDisplay()
            } else if name == "clear" || node.parent?.name == "clear" {
                currentInput = ""
                updateInputDisplay()
            } else if name == "submit" || node.parent?.name == "submit" {
                submitAnswer()
            } else if name == "cancel" || node.parent?.name == "cancel" {
                onCancel?()
            }
        }
    }
    
    private func updateInputDisplay() {
        if let inputLabel = childNode(withName: "//input_display") as? SKLabelNode {
            inputLabel.text = currentInput
        }
    }
    
    private func submitAnswer() {
        guard let answer = Int(currentInput) else { return }
        
        if answer == challenge.answer {
            onSuccess?()
        } else {
            // Show error and regenerate
            currentInput = ""
            updateInputDisplay()
            generateChallenge()
            
            let errorLabel = SKLabelNode(text: "Try again!")
            errorLabel.fontName = "Avenir-Medium"
            errorLabel.fontSize = 18
            errorLabel.fontColor = .red
            errorLabel.position = CGPoint(x: frame.midX, y: frame.midY - 100)
            addChild(errorLabel)
            
            errorLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }
}