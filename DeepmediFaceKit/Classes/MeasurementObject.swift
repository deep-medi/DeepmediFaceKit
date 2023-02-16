
import UIKit

public class MeasurementObject: NSObject {
    public enum gender: Int {
        case male = 0, female = 1
    }
    
    let model = Model.shared
    
    public override init() {
        super.init()
    }
    
    public func setMeasurementTime(_ time: Int?) {
        self.model.measurementTime = time ?? 30
    }
    
    public func setWindowSecond(_ time: Int?) {
        self.model.windowSec = time ?? 15
    }
    
    public func setOverlappingSecond(_ time: Int?) {
        self.model.overlappingSec = time ?? 2
    }
    
    public func setUserInformation(age: Int?, gender: MeasurementObject.gender?, height: Int?, weight: Int?) {
        self.model.age = age ?? 20
        self.model.gender = gender?.rawValue ?? 0
        self.model.height = height ?? 160
        self.model.weight = weight ?? 60
    }
}
