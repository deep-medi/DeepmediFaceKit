//
//  CameraPreView.swift
//
//  Created by Demian on 2023/02/09.
//

import Foundation
import AVKit

class CameraPreView: UIView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  func setupPreview(_ previewLayer: AVCaptureVideoPreviewLayer) {
    self.layer.addSublayer(previewLayer)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.position = CGPoint(x: 0.0, y: 0.0)
    previewLayer.frame.size = CGSize(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
