//
//  ParentalGate.swift
//  fish-puzzles
//
//  COPPA-compliant parental gate system (UIKit-based)
//

import UIKit

protocol ParentalGateDelegate: AnyObject {
    func parentalGateDidSucceed()
    func parentalGateDidFail()
    func parentalGateDidCancel()
}

final class ParentalGate {
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

        if let alert = alertController {
            viewController.present(alert, animated: true)
        }
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

