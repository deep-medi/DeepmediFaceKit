//
//  ViewModel.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/15.
//

import RxSwift

class ViewModel {
    let completeMeasurement = BehaviorSubject(value: (false, URL(string: "")))
    let secondRemaining = PublishSubject<Double>()
    let measurementCompleteRatio = PublishSubject<String>()
}
