//
//  DateExtension.swift
//  SolarCalculator
//
//  Created by apple on 28/07/18.
//  Copyright © 2018 Aakash Srivastav. All rights reserved.
//

import Foundation

extension Date {
    
    func adding(_ component: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: component, value: value, to: self)!
    }
}
