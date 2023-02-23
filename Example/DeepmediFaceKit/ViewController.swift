//
//  ViewController.swift
//  DeepmediFaceKit
//
//  Created by demianjun on 02/03/2023.
//  Copyright (c) 2023 demianjun. All rights reserved.
//

import UIKit
import DeepmediFaceKit
import AVKit
import SnapKit
import Then

class ViewController: UIViewController {
    
    let session = AVCaptureSession()
    let captureDevice = AVCaptureDevice(uniqueID: "Capture")
    
    let measurement = MeasurementObject()
    let header = Header()
    let camera = CameraObject()
    
    let faceDetetion = FaceDetection()
    
    let preview = CameraPreView().then { pv in
        pv.backgroundColor = .gray
    }
    
    let detectionView = UIView()
    
    let startButton = UIButton().then { b in
        b.setTitle("Start", for: .normal)
        b.backgroundColor = .yellow
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkOutput()
        measurement.setMeasurementTime(30)
        measurement.setWindowSecond(15)
        measurement.setOverlappingSecond(2)
        measurement.setUserInformation(age: 20, gender: .male, height: 160, weight: 60)
        
        camera.initalized(session: session, captureDevice: captureDevice)
        camera.setup(delegate: faceDetetion)
        
        let header = header.v2Header(method: .post, uri: "", secretKey: "", apiKey: "")
        
        self.setupUI()
    }
    
    func setupUI() {
        self.view.addSubview(preview)
        self.view.addSubview(detectionView)
        self.view.addSubview(startButton)
        
        let layer = camera.previewLayer()
        let width = UIScreen.main.bounds.width * 0.8,
            height = UIScreen.main.bounds.height * 0.8
        
        preview.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(width)
            make.height.equalTo(height)
        }
        
        detectionView.snp.makeConstraints { make in
            make.top.equalTo(preview).offset(height * 0.2)
            make.centerX.equalTo(preview)
            make.width.height.equalTo(width * 0.7)
        }
        
        startButton.snp.makeConstraints { make in
            make.width.height.equalTo(width * 0.3)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-80)
        }
        
        startButton.layer.cornerRadius = (width * 0.3) / 2
        startButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        
        preview.setup(preview: layer,
                      position: CGPoint(x: 0, y: 0),
                      size: CGSize(width: width, height: height))
        
        faceDetetion.detectionArea = detectionView
        faceDetetion.previewLayer = layer
    }
    
    @objc func start() {
        self.session.startRunning()
    }
    
    func checkOutput() {
        faceDetetion.finishedMeasurement() { (successed, url) in
            if successed {
                self.session.stopRunning()
                print(url)
            } else {
                print("error")
            }
        }
        
        faceDetetion.timesLeft { second in
            print("second: \(second)")
        }
        
        faceDetetion.numberOfData { count in
            print("count: \(count)")
        }
        
        faceDetetion.filteredData { filtered in
            
        }
    }
}

