
import UIKit
import AVKit
import MLKitFaceDetection
import MLKitVision
import CoreMotion
import Then
import Alamofire

public class MeasurementObject: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public enum gender: Int {
        case male = 0, female = 1
    }
    let header = Header()
    let cameraSetup = CameraSetup()
    let model = Model.shared
    
    public override init() {
        super.init()
        print("\(String(describing: OpenCVWrapper.openCVVersionString()))")
    }
    
    public func setMeasurementTime(_ time: Int) {
        self.model.measurementTime = time
    }
    public func setWindowSecond(_ time: Int) {
        self.model.windowSec = time
    }
    public func setOverlappingSecond(_ time: Int) {
        self.model.overlappingSec = time
    }
    public func setUserInformation(age: Int?, gender: MeasurementObject.gender?, height: Int?, weight: Int?) {
        self.model.age = age ?? 20
        self.model.gender = gender?.rawValue ?? 0
        self.model.height = height ?? 160
        self.model.weight = weight ?? 60
    }
    
    public func makeSignature(method: Header.method, uri: String, secretKey: String, apiKey: String) -> HTTPHeaders {
        return self.header.v2Header(method: method, uri: uri, secretKey: secretKey, apiKey: apiKey)
    }
    
    public func initCameraModel(session: AVCaptureSession, captureDevice: AVCaptureDevice?) {
        self.cameraSetup.initModel(session: session, captureDevice: captureDevice)
    }
    
    public
    
    public func setupCamera(delegate viewController: AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.cameraSetup.startDetection()
        self.cameraSetup.setupCameraFormat(30.0)
        self.cameraSetup.setupVideoOutput(viewController)
    }
}
