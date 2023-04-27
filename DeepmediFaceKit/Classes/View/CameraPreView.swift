//
//  CameraPreView.swift
//
//  Created by Demian on 2023/02/09.
//

import Foundation
import AVKit

public class CameraPreview: UIView {
    
    private let model = Model.shared
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public func setup(
        layer: AVCaptureVideoPreviewLayer,
        bound: CGRect
    ) {
        self.model.previewLayer = layer
        self.layer.addSublayer(layer)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bound
        print("layer: \(layer.frame)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
