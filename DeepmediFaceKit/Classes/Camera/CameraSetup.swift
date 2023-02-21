//
//  CameraSetup.swift
//
//  Created by Demian on 2023/02/09.
//

import Foundation
import AVKit

class CameraSetup: NSObject {
  private var session = AVCaptureSession()
  private var captureDevice: AVCaptureDevice?
  private var customISO: Float? = 30
  private let device = UIDevice.current
  
  func initModel(session: AVCaptureSession, captureDevice: AVCaptureDevice?) {
    self.session = session
    self.captureDevice = captureDevice
  }
  
  func useSession() -> AVCaptureSession {
    return self.session
  }
  
  func useCaptureDevice() -> AVCaptureDevice? {
    return self.captureDevice
  }
  
  func usePreViewLayer() -> AVCaptureVideoPreviewLayer {
    let preViewLayer = AVCaptureVideoPreviewLayer(session: session)
    return preViewLayer
  }
  
  @available(iOS 10.0, *)
  func startDetection() {
    self.session.sessionPreset = .low
    guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { fatalError("capture device error") }
    self.captureDevice = captureDevice
    if self.session.inputs.isEmpty {
      guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { fatalError("input error") }
      self.session.addInput(input)
    }
  }
  
  func setupCameraFormat(_ framePerSec: Double) {

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
    
    if try! self.captureDevice?.lockForConfiguration() != nil {
      try! self.captureDevice?.lockForConfiguration()
      guard let tempCurrentFormat = currentFormat else { fatalError("current format")}
      self.captureDevice?.activeFormat = tempCurrentFormat
      self.captureDevice?.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(tempFramePerSec))
      self.captureDevice?.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(tempFramePerSec))
      self.captureDevice?.unlockForConfiguration()
    }
  }
  
  func setUpCatureDevice(_ framePerSec: Double) {
    try! self.captureDevice?.lockForConfiguration()
    let cmTime = CMTimeMake(value: 1, timescale: Int32(framePerSec))// 10/600 초
    captureDevice?.setExposureModeCustom(duration: cmTime, iso: self.customISO ?? 30, completionHandler: nil)
    captureDevice?.unlockForConfiguration()
  }
  
//  @objc func correctColor() {
//    try! self.captureDevice?.lockForConfiguration()
//    let gainset = AVCaptureDevice.WhiteBalanceGains(redGain: 1.0,
//                                                    greenGain: 1.0, // 3 -> 1 edit
//                                                    blueGain: 1.0)
//    self.captureDevice?.setWhiteBalanceModeLocked(with: gainset,
//                                                  completionHandler: nil)
//    self.captureDevice?.unlockForConfiguration()
//  }
  
  func setupVideoOutput(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
    let videoOutput = AVCaptureVideoDataOutput()
    let captureQueue = DispatchQueue(label: "catpureQueue")
    
    videoOutput.setSampleBufferDelegate(delegate, queue: captureQueue)
    videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
    videoOutput.alwaysDiscardsLateVideoFrames = true//false

    if self.session.canAddOutput(videoOutput) {
      self.session.addOutput(videoOutput)
    } else {
      print("can not output")
    }
  }
}