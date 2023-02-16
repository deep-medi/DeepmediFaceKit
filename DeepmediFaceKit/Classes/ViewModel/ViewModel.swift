//
//  ViewModel.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/15.
//

import RxSwift

class ViewModel {
    
    let completeMeasurement = BehaviorSubject(value: (false, URL(string: "")))
    let numberOfData = PublishSubject<Int>()
    let filteredData = PublishSubject<Double>()
    let secondRemaining = PublishSubject<Int>()
}
