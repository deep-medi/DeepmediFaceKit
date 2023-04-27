//
//  CameraPreView.swift
//
//  Created by Demian on 2023/02/09.
//

import Foundation
import AVKit

public class CameraPreview: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public func setup(
        layer: AVCaptureVideoPreviewLayer,
        bound: CGRect
    ) {
        self.layer.addSublayer(layer)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bound
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
