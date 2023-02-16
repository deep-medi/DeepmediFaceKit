//
//  Document.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/09.
//

import UIKit

open class Document {
    enum Sensor {
      case acc, gyro
    }
    
    private let fileManager = FileManager()
    private let dataModel = DataModel.shared
      
  // MARK: 측정데이터 파일생성
    func makeDocuFromData() {
      let docuURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
      let faceFilePath = docuURL.appendingPathComponent("PPG_DATA_ios.txt")
      
      self.dataModel.rgbDataPath = faceFilePath
      self.transrateFaceDataToTxtFile(faceFilePath)
    }
      
      func makeDocuFromChestData() {
        let docuURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let chestFilePath = docuURL.appendingPathComponent("data.bin")
        self.dataModel.fileDataPath = chestFilePath
        self.transrateChestDataToByteArr(chestFilePath)
      }
    
    private func transrateFaceDataToTxtFile(_ fileURL: URL) {
      
      self.dataModel.rgbDatas.forEach { dataMass in
        self.dataModel.rgbDataToArr.append("\(dataMass.0 as Float64)\t" + "\(dataMass.1)\t" + "\(dataMass.2)\t" + "\(dataMass.3)\n")
      }
      
      for i in self.dataModel.rgbDataToArr.indices {
        self.dataModel.rgbSubStr += "\(self.dataModel.rgbDataToArr[i])"
      }
      
      try? self.dataModel.rgbSubStr.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
    }
    
    private func transrateChestDataToByteArr (_ fileURL: URL) {
      
      var data = Data()
      
      let length = self.byteArray(from: 900),
          chestSize = self.byteArray(from: 32)
      
      for i in length.indices {
        if i > 3 {
          let lengthArr = length[i]
          self.dataModel.byteData.append(lengthArr)
        }
      }
      
      for i in chestSize.indices {
        if i > 3 {
          let sizeArr = chestSize[i]
          self.dataModel.byteData.append(sizeArr)
        }
      }
      
      for i in chestSize.indices {
        if i > 3 {
          let sizeArr = chestSize[i]
          self.dataModel.byteData.append(sizeArr)
        }
      }
      
      self.dataModel.timeStamp.forEach { time in
        
        let timeDiff = Int((time - self.dataModel.timeStamp.first!) / 1000),
            timeToByteArr = self.byteArray(from: timeDiff)
        
        for i in timeToByteArr.indices {
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
    
    private func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.bigEndian, Array.init)
    }
    
    func makeDocuFromMeasureData(data: Sensor,
                                 dataMass: [(Double, Float, Float, Float)],
                                 dataArr: inout [String],
                                 dataStr: inout String) {
      
      let docuURL = self.fileManager.urls(for: .documentDirectory,
                                          in: .userDomainMask).first!
      switch data {
      case .acc:
        let file = docuURL.appendingPathComponent("ACC_DATA_ios.txt")
        self.dataModel.accDataPath = file
        
        self.transrateDataToTxtFile(file,
                                    dataMass,
                                    &dataArr,
                                    &dataStr)
        
      case .gyro:
        let file = docuURL.appendingPathComponent("GYRO_DATA_ios.txt")
        self.dataModel.gyroDataPath = file
        
        self.transrateDataToTxtFile(file,
                                    dataMass,
                                    &dataArr,
                                    &dataStr)
      }
    }
    
    private func transrateDataToTxtFile (_ file: URL,
                                         _ dataMass: [(Double, Float, Float, Float)],
                                         _ dataArr: inout [String],
                                         _ dataStr: inout String) {
      
      for i in dataMass.indices {
        dataArr.append(
          "\(dataMass[i].0 as Float64)\t"
            + "\(dataMass[i].1)\t"
            + "\(dataMass[i].2)\t"
            + "\(dataMass[i].3)\n"
        )
      }
      
      for i in dataArr.indices {
        dataStr += "\(dataArr[i])"
      }
      
      try? dataStr.write(to: file, atomically: true, encoding: String.Encoding.utf8)
    }
}
