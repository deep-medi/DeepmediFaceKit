//
//  ViewController.swift
//  DeepmediFaceKit
//
//  Created by demianjun on 02/03/2023.
//  Copyright (c) 2023 demianjun. All rights reserved.
//

import UIKit
import AVKit
import SnapKit
import Alamofire
import DeepmediFaceKit

class ViewController: UIViewController, FaceRecognitionProtocol {
    var faceRecognitionAreaView: UIView = FaceRecognitionAreaView(
        pattern: [24, 10],
        strokeColor: .white,
        lineWidth: 11.8
    )
    
    var tempView = UIView().then { v in
        v.layer.borderColor = UIColor.red.cgColor
        v.layer.borderWidth = 3
    }
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    let session = AVCaptureSession()
    let captureDevice = AVCaptureDevice(uniqueID: "Capture")

    let header = Header()
    let camera = CameraObject()
    
    let faceMeasureKit = FaceMeasureKit()
    let faceMeasureKitModel = FaceMeasureKitModel()

    let preview = CameraPreview()
    let startButton = UIButton().then { b in
        b.setTitle("Start", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        completionMethod()
        
        camera.initalized(
            delegate: faceMeasureKit,
            session: session,
            captureDevice: captureDevice
        )
        faceMeasureKitModel.setMeasurementTime(30)
        faceMeasureKitModel.setWindowSecond(15)
        faceMeasureKitModel.setOverlappingSecond(2)
        faceMeasureKitModel.willUseFaceRecognitionArea(false)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        self.setupUI()
        
//        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
//            self.faceMeasureKit.startSession()
//        }
    }
    
    override func viewDidLayoutSubviews() {
        preview.setup(
            layer: previewLayer,
            frame : preview.frame
        )

        faceMeasureKitModel.injectingRecognitionAreaView(faceRecognitionAreaView)
    }

    @objc func start() {
        DispatchQueue.global(qos: .background).async {
            self.faceMeasureKit.startSession()
        }
    }

    func completionMethod() {
        faceMeasureKit.measurementCompleteRatio { ratio in
            print("complete ratio: \(ratio)")
        }

        faceMeasureKit.timesLeft { second in
            print("second: \(second)")
        }
        
        faceMeasureKit.finishedMeasurement { (successed, path) in
            if let path = path,
               successed {
                DispatchQueue.global(qos: .background).async {
                    self.faceMeasureKit.stopSession()
                }

                let header = self.header.v2Header(method: .post,
                                                  uri: "offered uri",
                                                  secretKey: "offered secret key",
                                                  apiKey: "offered api key")

            } else {
                print("error")
            }
        }
    }

    func setupUI() {
        self.view.addSubview(preview)
        self.view.addSubview(faceRecognitionAreaView)
        self.view.addSubview(startButton)
        let width = UIScreen.main.bounds.width * 0.7,
            height = UIScreen.main.bounds.height * 0.7
//        let width = UIScreen.main.bounds.width,
//            height = UIScreen.main.bounds.height

        preview.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(30)
            make.width.equalTo(width)
            make.height.equalTo(height)
        }

        faceRecognitionAreaView.snp.makeConstraints { make in
            make.top.equalTo(preview).offset(height * 0.2)
            make.centerX.equalTo(preview)
            make.width.height.equalTo(width * 0.7)
        }

        startButton.snp.makeConstraints { make in
            make.width.height.equalTo(UIScreen.main.bounds.width * 0.3)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-80)
        }

        startButton.layer.cornerRadius = (UIScreen.main.bounds.width * 0.3) / 2
        startButton.addTarget(
            self,
            action: #selector(start),
            for: .touchUpInside
        )
    }
}


struct CodableStruct: Codable {
    let message: String
    let result: Int
}
