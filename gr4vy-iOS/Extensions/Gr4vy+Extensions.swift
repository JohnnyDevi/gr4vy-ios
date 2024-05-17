//
//  Gr4vy+Extensions.swift
//  gr4vy-ios
//
//  Created by Arthur Tristan Ramos on 5/17/24.
//

import UIKit

extension Gr4vy {
    
    // MARK: This function enables user interaction based on argument to be passed to `activate`.
    func enableUserInteraction(activate mustBeEnabled: Bool) {
        if let currentScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let keyWindow = currentScene.windows.first {
                // Access the key window and perform your operations
                keyWindow.isUserInteractionEnabled = mustBeEnabled
            }
        }
    }
    
}
