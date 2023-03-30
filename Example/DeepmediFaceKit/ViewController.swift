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
import Then
import Alamofire
import DeepmediFaceKit

class ViewController: UIViewController, FaceRecognitionProtocol {
    
    let session = AVCaptureSession()
    let captureDevice = AVCaptureDevice(uniqueID: "Capture")

    let faceMeasureKitModel = FaceMeasureKitModel()
    let header = Header()
    let camera = CameraObject()
    let faceMeasureKit = FaceMeasureKit()

    let preview = CameraPreview()
    let faceRecognitionAreaView = FaceRecognitionAreaView(
        pattern: [24, 10],
        strokeColor: .white,
        lineWidth: 11.8
    )

    let startButton = UIButton().then { b in
        b.setTitle("Start", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        checkOutput()
        faceMeasureKitModel.setMeasurementTime(30)
        faceMeasureKitModel.setWindowSecond(15)
        faceMeasureKitModel.setOverlappingSecond(2)
        faceMeasureKitModel.setUserInformation(age: 20, gender: .male, height: 160, weight: 60)
        faceMeasureKitModel.willUseFaceRecognitionArea(true)

        camera.initalized(session: session, captureDevice: captureDevice)
        camera.setup(delegate: faceMeasureKit)

        self.setupUI()
    }

    @objc func start() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }

    func checkOutput() {
        faceMeasureKit.finishedMeasurement { (successed, path) in
            if let path = path,
               successed {
                DispatchQueue.global(qos: .background).async {
                    self.session.stopRunning()
                }

                let offeredUri = "offered uri"
                let offeredUrl = "offered urL"
                let params = ["age": "\(20)",
                              "gender": "\(0)",
                              "overlapping_sec": "\(3)",
                              "window_sec": "\(10)"] as [String: String]

                let header = self.header.v2Header(method: .post,
                                                  uri: offeredUri,
                                                  secretKey: "offered secret key",
                                                  apiKey: "offered api key")

                AF.upload(multipartFormData: { multipartFormData in
                    for (key, value) in params {
                        multipartFormData.append("\(value)".data(using: .utf8)!, withName: key)
                    }
                    multipartFormData.append(path, withName: "rgb")
                },
                          to: offeredUrl,
                          method: .post,
                          headers: header)
                .responseDecodable(of: CodableStruct.self) { response in
                    switch response.result {

                    case .success(let res):
                        guard res.result == 200 else { return print("multi ppg stress result return") }
                        let response = res.message
                        print("responose: \(response)")

                    case .failure(let err):
                        print("data err: " + err.localizedDescription)
                    }
                }
            } else {
                print("error")
            }
        }

        faceMeasureKit.measurementCompleteRatio { completeRatio in
            print("complete ratio: \(completeRatio)")
        }

        faceMeasureKit.timesLeft { second in
            print("second: \(second)")
        }
    }

    func setupUI() {
        self.view.addSubview(preview)
        self.view.addSubview(faceRecognitionAreaView)
        self.view.addSubview(startButton)

        let layer = camera.previewLayer()
        let width = UIScreen.main.bounds.width * 0.8,
            height = UIScreen.main.bounds.height * 0.8

        preview.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(width)
            make.height.equalTo(height)
        }

        faceRecognitionAreaView.snp.makeConstraints { make in
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
        startButton.addTarget(
            self,
            action: #selector(start),
            for: .touchUpInside
        )

        preview.setup(
            preview: layer,
            position: CGPoint(x: 0, y: 0),
            size: CGSize(width: width, height: height)
        )

        faceMeasureKitModel.injectingRecognitionAreaView(faceRecognitionAreaView)
        faceMeasureKitModel.previewLayer(layer)
    }
}


struct CodableStruct: Codable {
    let message: String
    let result: Int
}
