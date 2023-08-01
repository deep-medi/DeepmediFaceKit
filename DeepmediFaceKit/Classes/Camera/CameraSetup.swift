//
//  CameraSetup.swift
//
//  Created by Demian on 2023/02/09.
//

import Foundation
import AVKit

class CameraSetup: NSObject {
    
    static let shared = CameraSetup()
    
    private var session = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var customISO: Float? = 30
    private let device = UIDevice.current
    
    func initModel(
        session: AVCaptureSession,
        captureDevice: AVCaptureDevice?
    ) {
        self.session = session
        self.captureDevice = captureDevice
    }
    
    func useSession() -> AVCaptureSession {
        return self.session
    }
    
    func useCapterDevice() -> AVCaptureDevice? {
        return self.captureDevice
    }
    
    @available(iOS 10.0, *)
    func startDetection() {
        self.session.sessionPreset = .low
        guard let captureDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else { fatalError("capture device error") }
        
        self.captureDevice = captureDevice
        
        if self.session.inputs.isEmpty {
            guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { fatalError("input error") }
            self.session.addInput(input)
        }
    }
    
    func setupCameraFormat(
        _ framePerSec: Double
    ) {
        var currentFormat: AVCaptureDevice.Format?,
            tempFramePerSec = Double()
        
        guard let captureDeviceFormats = self.captureDevice?.formats else { fatalError("capture device") }
        
        for format in captureDeviceFormats {
            let ranges = format.videoSupportedFrameRateRanges
            let frameRates = ranges[0]
            
            if (frameRates.maxFrameRate == framePerSec) {
                let videoFormatDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                if videoFormatDimensions.width <= Int32(2000) && videoFormatDimensions.height <= Int32(1100) {
                    
                    currentFormat = format
                    tempFramePerSec = 30.0
                }
            }
        }
        
        guard let tempCurrentFormat = currentFormat,
              try! self.captureDevice?.lockForConfiguration() != nil else { return print("current format")}
        
        try! self.captureDevice?.lockForConfiguration()
        self.captureDevice?.activeFormat = tempCurrentFormat
        self.captureDevice?.activeVideoMinFrameDuration = CMTimeMake(
            value: 1,
            timescale: Int32(tempFramePerSec)
        )
        self.captureDevice?.activeVideoMaxFrameDuration = CMTimeMake(
            value: 1,
            timescale: Int32(tempFramePerSec)
        )
        self.captureDevice?.unlockForConfiguration()
    }
    
    func setUpCatureDevice() {
        try! self.captureDevice?.lockForConfiguration()
        captureDevice?.exposureMode = .locked
        captureDevice?.unlockForConfiguration()
    }
    
    func setupVideoOutput(
        _ delegate: AVCaptureVideoDataOutputSampleBufferDelegate
    ) {
        let videoOutput = AVCaptureVideoDataOutput()
        let captureQueue = DispatchQueue(label: "catpureQueue")
        
        videoOutput.setSampleBufferDelegate(
            delegate,
            queue: captureQueue
        )
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true//false
        
        if self.session.canAddOutput(videoOutput) {
            self.session.addOutput(videoOutput)
        } else {
            print("can not output")
        }
    }
}
