//
//  Utilities.swift
//  SolarCalculator
//
//  Created by Aakash Srivastav on 28/07/18.
//  Copyright © 2018 Aakash Srivastav. All rights reserved.
//

import UIKit

func print_debug <T>(_ object: T) {
    #if DEBUG
    print(object)
    #endif
}
