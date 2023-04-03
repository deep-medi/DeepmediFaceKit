//
//  Model.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/09.
//

import UIKit
import AVKit

class Model {
    static let shared = Model()
    
    var useFaceRecognitionArea: Bool
    
    var faceRecognitionAreaView: UIView?
    var previewLayer: AVCaptureVideoPreviewLayer?
        
    var measurementTime: Double {
        didSet {
            if self.measurementTime < 30.0 {
                self.measurementTime = 30.0
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
        self.faceRecognitionAreaView = UIView()
        self.previewLayer = AVCaptureVideoPreviewLayer()
        
        self.useFaceRecognitionArea = true
        
        self.age = 20
        self.gender = 0
        self.height = 160
        self.weight = 60
        
        self.measurementTime = 30.0
        self.windowSec = 15
        self.overlappingSec = 2
    }
}
