//
//  CameraObject.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/14.
//

import Foundation
import AVKit

public class CameraObject: NSObject {
    let cameraSetup = CameraSetup()
    
    public func initalized(session: AVCaptureSession, captureDevice: AVCaptureDevice?) {
        self.cameraSetup.initModel(session: session, captureDevice: captureDevice)
    }
    
    public func setup(delegate object: AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.cameraSetup.startDetection()
        self.cameraSetup.setupCameraFormat(30.0)
        self.cameraSetup.setupVideoOutput(object)
    }
    
    public func previewLayer() -> AVCaptureVideoPreviewLayer {
        return self.cameraSetup.usePreViewLayer()
    }
}
