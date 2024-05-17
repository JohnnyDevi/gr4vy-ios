//
//  UINavigationController+Extensions.swift
//  gr4vy-ios
//
//  Created by Arthur Tristan Ramos on 5/17/24.
//

import UIKit

extension UINavigationController {
    
    // MARK: This resolves overlapping of navbatr titles and this makes navbar background color.
    func withSetupWhiteNavbar(for navigationController: UINavigationController) -> UINavigationController {
        let barAppearance = UINavigationBarAppearance()
        barAppearance.backgroundColor = UIColor(red: 85, green: 85, blue: 85, alpha: 1.0)
        
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.standardAppearance = barAppearance
        navigationController.navigationBar.scrollEdgeAppearance = barAppearance
        
        return navigationController
    }
    
}
