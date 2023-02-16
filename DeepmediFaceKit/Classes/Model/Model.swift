//
//  Model.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/09.
//

import UIKit

class Model {
    static let shared = Model()
    
    var measurementAccTime = 10
    var measurementTime: Int {
        didSet {
            if self.measurementTime < 30 {
                self.measurementTime = 30
            }
        }
    }
    
    var windowSec: Int
    var overlappingSec: Int
    var age: Int,
        height: Int,
        weight: Int
    var gender: Int {
        didSet {
            if self.gender != 0 || self.gender != 1 {
                self.gender = 0
            }
        }
    }
    
    init() {
        self.age = 20
        self.gender = 0
        self.height = 160
        self.weight = 60
        
        self.measurementTime = 30
        self.windowSec = 15
        self.overlappingSec = 2
    }
}
