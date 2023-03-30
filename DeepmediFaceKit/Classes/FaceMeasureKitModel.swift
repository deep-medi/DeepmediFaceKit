
import UIKit
import AVKit

public class FaceMeasureKitModel: NSObject {
    public enum gender: Int {
        case male = 0, female = 1
    }
    
    let model = Model.shared
    
    public override init() {
        super.init()
    }
    
    public func previewLayer(
        _ layer: AVCaptureVideoPreviewLayer
    ) {
        self.model.previewLayer = layer
    }
    
    public func injectingRecognitionAreaView(
        _ view: UIView
    ) {
        self.model.faceRecognitionAreaView = view
    }
    
    public func willUseFaceRecognitionArea(
        _ use: Bool
    ) {
        self.model.useFaceRecognitionArea = use
    }
    
    public func setMeasurementTime(
        _ time: Double?
    ) {
        self.model.measurementTime = time ?? 30.0
    }
    
    public func setWindowSecond(
        _ time: Int?
    ) {
        self.model.windowSec = time ?? 15
    }
    
    public func setOverlappingSecond(
        _ time: Int?
    ) {
        self.model.overlappingSec = time ?? 2
    }
    
    public func setUserInformation(
        age: Int?,
        gender: FaceMeasureKitModel.gender?,
        height: Int?,
        weight: Int?
    ) {
        self.model.age = age ?? 20
        self.model.gender = gender?.rawValue ?? 0
        self.model.height = height ?? 160
        self.model.weight = weight ?? 60
    }
}
