//
//  CameraPreView.swift
//
//  Created by Demian on 2023/02/09.
//

import Foundation
import AVKit

public class CameraPreView: UIView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
    public func setup(preview layer: AVCaptureVideoPreviewLayer, position: CGPoint, size: CGSize) {
        self.layer.addSublayer(layer)
        layer.videoGravity = .resizeAspectFill
        layer.position = position
        layer.frame.size = size
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
