//
//  RGBData.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/15.
//

import UIKit

final class RGBData {
    enum RGB {
        case R, G, B
    }
    
    //-----------------RGB--------------------
    private let dataModel = DataModel.shared
    
    private var r: Float = 0, g: Float = 0, b: Float = 0, timeStamp: Double = 0
    
    func initRGBData() {
        self.dataModel.rData.removeAll()
        self.dataModel.gData.removeAll()
        self.dataModel.bData.removeAll()
        self.dataModel.timeStamp.removeAll()
        
        self.dataModel.rgbDatas.removeAll()
        self.dataModel.rgbDataToArr.removeAll()
        self.dataModel.rgbSubStr.removeAll()
    }
    
    // MARK: RGB값 수집
    func collectRGB(
        timeStamp: Double,
        r: Float,
        g: Float,
        b: Float
    ) {
        let dataFormat = (timeStamp, r, g, b)
        self.dataModel.gTempData.append(g)
        self.dataModel.rData.append(r)
        self.dataModel.gData.append(g)
        self.dataModel.bData.append(b)
        self.dataModel.timeStamp.append(timeStamp)
        self.dataModel.rgbDatas.append(dataFormat)
    }
}
