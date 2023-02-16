//
//  DataModel.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/09.
//

import UIKit

open class DataModel {
    static let shared = DataModel()
    
    var rgbDataPath: URL?,
        fileDataPath: URL?
    
    var gTempData = [Float]()
    
    var rData = [Float](),
        gData = [Float](),
        bData = [Float](),
        timeStamp = [Double]()
    
    var rgbDatas = [(Double(),
                     Float(),
                     Float(),
                     Float())]
    
    var rgbDataToArr = [String]()
    var rgbSubStr = String()
    
    var bytesArr = [[UInt8]]()
    var byteData = [UInt8]()
    
    var temp = [UInt8]()
    
    var accDataPath: URL?,
        gyroDataPath: URL?
    
    var accXdata = [Float](),
        accYdata = [Float](),
        accZdata = [Float]()
    
    var accDatas = [(Double(),
                     Float(),
                     Float(),
                     Float())]
    
    var accDataToArr = [String]()
    var accSubStr = String()
    
    
    var gyroXdata = [Float](),
        gyroYdata = [Float](),
        gyroZdata = [Float]()
    
    var gyroDatas = [(Double(),
                      Float(),
                      Float(),
                      Float())]
    
    var gyroDataToArr = [String]()
    var gyroSubStr = String()
}
