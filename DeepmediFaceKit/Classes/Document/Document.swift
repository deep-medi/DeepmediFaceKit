//
//  Document.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/09.
//
import Foundation
import UIKit

public class Document {
    private let fileManager = FileManager()
    private let dataModel = DataModel.shared
    private let model = Model.shared
    
    // MARK: 측정데이터 파일생성
    func makeDocument() {
        let docuURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        var rgbFilePath = docuURL.appendingPathComponent("PPG_DATA_Face_ios.txt")
        self.dataModel.rgbDataPath = rgbFilePath
        self.transrateDataToTxtFile(rgbFilePath)
    }
    
    func makeDocuFromChestData() {
        let docuURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let chestFilePath = docuURL.appendingPathComponent("data.bin")
        self.dataModel.fileDataPath = chestFilePath
        self.transrateChestDataToByteArr(chestFilePath)
    }
    
    private func transrateFaceDataToTxtFile(
        _ fileURL: URL
    ) {
        
        self.dataModel.rgbData.forEach { dataMass in
            self.dataModel.rgbDataToArr.append("\(dataMass.0 as Float64)\t" + "\(dataMass.1)\t" + "\(dataMass.2)\t" + "\(dataMass.3)\n")
        }
        
        for i in self.dataModel.rgbDataToArr.indices {
            self.dataModel.rgbSubStr += "\(self.dataModel.rgbDataToArr[i])"
        }
        
        try? self.dataModel.rgbSubStr.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
    }
    
    private func transrateChestDataToByteArr(
        _ fileURL: URL
    ) {
        
        var data = Data()
        
        let length = self.byteArray(from: 900),
            chestSize = self.byteArray(from: 32)
        
        for i in length.indices.reversed() {
            if i > 3 {
                let lengthArr = length[i]
                self.dataModel.byteData.append(lengthArr)
            }
        }
        
        for i in chestSize.indices.reversed() {
            if i > 3 {
                let sizeArr = chestSize[i]
                self.dataModel.byteData.append(sizeArr)
            }
        }
        
        for i in chestSize.indices.reversed() {
            if i > 3 {
                let sizeArr = chestSize[i]
                self.dataModel.byteData.append(sizeArr)
            }
        }
        
        self.dataModel.timeStamp.forEach { time in
            let timeDiff = Int((time - self.dataModel.timeStamp.first!) / 1000),
                timeToByteArr = self.byteArray(from: timeDiff)
            
            for i in timeToByteArr.indices.reversed() {
                if i > 3 {
                    let timeArr = timeToByteArr[i]
                    self.dataModel.byteData.append(timeArr)
                }
            }
        }
        
        self.dataModel.bytesArr.forEach { byteArr in
            byteArr.forEach { byte in
                self.dataModel.byteData.append(byte)
            }
        }
        
        data = NSData(bytes: self.dataModel.byteData, length: self.dataModel.byteData.count) as Data
        
        try? data.write(to: fileURL, options: .atomic)
    }
    
    private func byteArray<T>(
        from value: T
    ) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.bigEndian, Array.init)
    }
    
    private func transrateDataToTxtFile(
        _ file: URL
    ) {
        var data = self.dataModel.rgbData,
            dataToArr = self.dataModel.rgbDataToArr,
            dataSubStr = self.dataModel.rgbSubStr
        
        data.forEach { dataMass in
            dataToArr.append(
                "\(dataMass.0 as Float64)\t"
                + "\(dataMass.1)\t"
                + "\(dataMass.2)\t"
                + "\(dataMass.3)\n"
            )
        }
        
        for i in dataToArr.indices {
            dataSubStr += "\(dataToArr[i])"
        }
        
        try? dataSubStr.write(
            to: file,
            atomically: true,
            encoding: String.Encoding.utf8
        )
    }
}
