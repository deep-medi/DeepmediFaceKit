//
//  FaceAreaView.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/15.
//

import UIKit

public class FaceAreaView: UIView {
    
    private let borderLayer = CAShapeLayer()
    
    public init(pattern: [NSNumber]? = nil, strokeColor: UIColor? = .white, lineWidth: CGFloat? = nil) {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        self.borderLayer.lineDashPattern = pattern
        self.borderLayer.strokeColor = strokeColor?.cgColor
        self.borderLayer.lineWidth = lineWidth ?? 5
        self.borderLayer.fillColor = UIColor.clear.cgColor
        self.borderLayer.backgroundColor = UIColor.clear.cgColor
        
        layer.addSublayer(self.borderLayer)
    }
    
    public override func draw(_ rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect,cornerRadius: rect.width / 2).cgPath
        self.borderLayer.path = path
    }
    
    func useBorderLayer() -> CAShapeLayer {
        return self.borderLayer
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
