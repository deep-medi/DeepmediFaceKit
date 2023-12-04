//
//  MeasurementModel.swift
//  DeepmediFaceKit
//
//  Created by 딥메디 on 2023/12/01.
//

import Foundation
import RxSwift

class MeasurementModel {
    let secondRemaining = PublishSubject<Int>()
    let measurementCompleteRatio = PublishSubject<String>()
    let measurementStop = PublishSubject<Bool>()
    
    let checkRealFace = BehaviorSubject(value: false)
    let completeMeasurement = BehaviorSubject(value: (false, URL(string: "")))
    let chestMeasurementComplete = BehaviorSubject(value: (false, URL(string: "")))
}
