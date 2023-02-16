//
//  Protocol.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/16.
//

import UIKit
import AVKit

protocol FaceDetectionArea {
    var detectionArea: UIView { get set }
    var previewLayer: AVCaptureVideoPreviewLayer { get }
}

