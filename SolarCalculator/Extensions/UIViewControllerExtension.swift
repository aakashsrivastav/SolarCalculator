//
//  UIViewControllerExtension.swift
//  SolarCalculator
//
//  Created by apple on 28/07/18.
//  Copyright © 2018 Aakash Srivastav. All rights reserved.
//

import UIKit

extension UIViewController {
    
    // Not using static as it won't be possible to override to provide custom storyboardID then
    class var storyboardID : String {
        return "\(self)"
    }
    
    static func instantiate(fromAppStoryboard appStoryboard: AppStoryboard) -> Self {
        return appStoryboard.viewController(self)
    }
}
