
import UIKit
import AVKit

public class FaceMeasureKitModel: NSObject {
    let model = Model.shared
    
    public override init() {
        super.init()
    }
    ///실제 얼굴인지 체크함(true로 설정시 사람임을 감지해야 측정됨)
    public func usingCheckRealFace(
        _ use: Bool
    ) {
        self.model.usingCheckRealFace = use
    }
    ///얼굴인식위치 사용설정 시 인식위치를 위한 View 주입
    public func injectingRecognitionAreaView(
        _ view: UIView
    ) {
        self.model.faceRecognitionAreaView = view
    }
    ///얼굴인식위치 사용설정(true로 설정시 .injectingRecognitionAreaView() 함수에 UIview를 넣어줘야 함)
    public func willUseFaceRecognitionArea(
        _ use: Bool
    ) {
        self.model.useFaceRecognitionArea = use
    }
    ///측정시간 설정(기본 최소측정시간 30초)
    public func setMeasurementTime(
        _ time: Double?
    ) {
        self.model.measurementTime = time ?? 30.0
    }
    ///윈도우 시간 설정(기본 최소시간 15초, 필요 없을 시 사용하지 않아도 됨)
    public func setWindowSecond(
        _ time: Int?
    ) {
        self.model.windowSec = time ?? 15
    }
    ///오버랩핑 시간 설정(기본 최소시간 2초, 필요 없을 시 사용하지 않아도 됨)
    public func setOverlappingSecond(
        _ time: Int?
    ) {
        self.model.overlappingSec = time ?? 2
    }
}
