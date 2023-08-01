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
        frame: CGRect
    ) {
        self.model.previewLayer = layer
        self.model.previewLayerBounds = self.frame
        self.layer.addSublayer(layer)
        layer.videoGravity = .resizeAspectFill
        layer.frame = CGRect(x: 0, y: 0,
                             width: frame.width,
                             height: frame.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
