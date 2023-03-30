//
//  Protocol.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/16.
//

import UIKit
import AVKit

public protocol FaceRecognitionProtocol {
    var faceRecognitionAreaView: UIView { get set }
    var previewLayer: AVCaptureVideoPreviewLayer { get }
}

