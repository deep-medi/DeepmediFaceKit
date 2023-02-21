//
//  FaceDetection.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/15.
//

import UIKit
import MLKitVision
import MLKitFaceDetection
import AVKit
import RxSwift
import RxCocoa
import CoreMotion
import Then

public class FaceDetection: NSObject, FaceDetectionArea {
    
    private let bag = DisposeBag()
    private let makeDocument = Document(),
                rgbModel = RGBData()
    private let dataModel = DataModel.shared,
                model = Model.shared
    private let viewModel = ViewModel()
    
    public var previewLayer = AVCaptureVideoPreviewLayer()
    
    public var detectionArea = UIView().then { v in
        v.layer.borderColor = UIColor.red.cgColor
        v.layer.borderWidth = 2
    }
    
    private var lastFrame: CMSampleBuffer?,
                gCIContext: CIContext?,
                cropFaceRect: CGRect?,
                cropChestRect: CGRect?
    
        // MARK: Property
    private var flag = false,
                sec = Int(), // 측정하는 시간
                preparingSec = Int() // 얼굴을 인식하고 준비하는 시간
    
    private var detectTimer = Timer()
    
    private let detectFaceAreaView = FaceAreaView(strokeColor: .white, lineWidth: 11.8) // 얼굴을 인식하는 위치
    
    public func finishedMeasurement(_ isSuccess: @escaping((Bool, URL?) -> ())) {
        let completion = self.viewModel.completeMeasurement
        completion
            .asDriver(onErrorJustReturn: (false, URL(string: "")))
            .drive(onNext: { result in
                isSuccess(result.0, result.1)
            })
            .disposed(by: bag)
    }
    
    public func timesLeft(_ com: @escaping((Int) -> ())) {
        let secondRemaining = self.viewModel.secondRemaining
        secondRemaining
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { remaining in
                com(remaining)
            })
            .disposed(by: bag)
    }
    
    public func numberOfData(_ com: @escaping((Int) -> ())) {
        let numberOfData = self.viewModel.numberOfData
        numberOfData
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { count  in
                com(count)
            })
            .disposed(by: bag)
    }
    
    public func filteredData(_ filtered: @escaping((Double) -> ())) {
        let filteredData = self.viewModel.filteredData
        filteredData
            .asDriver(onErrorJustReturn: 0.0)
            .drive(onNext: { data in
                filtered(data)
            })
            .disposed(by: bag)
    }
    
    public override init() {
        super.init()
        UIApplication.shared.isIdleTimerDisabled = true //측정중 화면 자동잠금을 막기 위해 설정
        self.sec = self.model.measurementTime
        self.preparingSec = 3
        if let openCVstr = OpenCVWrapper.openCVVersionString() {
            print("\(openCVstr)")
        }
    }
    
    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func collectDatas() {
        let completion = self.viewModel.completeMeasurement,
            secondRemaining = self.viewModel.secondRemaining
            
        self.rgbModel.initRGBData() // 중간에 쌓여있을 수 있는 데이터 초기화
        
        self.flag = false
        self.sec = self.model.measurementTime
        self.preparingSec = 1
        self.detectTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            secondRemaining.onNext(self.sec)
            self.sec -= 1
            if self.sec <= 0 {
                timer.invalidate()
                self.makeDocument.makeDocuFromData() //측정한 데이터 파일로 변환
                if let rgbPath = self.dataModel.rgbDataPath { //파일이 존재할때 api호출 시도
                    completion.onNext((result: true, url: rgbPath))
                } else {
                    completion.onNext((result: false, url: URL(string: "")))
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension FaceDetection: AVCaptureVideoDataOutputSampleBufferDelegate { // 카메라 이미지에서 데이터 수집을 위한 delegate
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvimgRef: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { fatalError("cvimg ref") }
        
        CVPixelBufferLockBaseAddress(cvimgRef, CVPixelBufferLockFlags(rawValue: 0))
        
        self.lastFrame = sampleBuffer
        
        let orientation = self.imageOrientation(fromDevicePosition: .front)
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = orientation
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(cvimgRef))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(cvimgRef))
        
        self.detectFacesOnDevice(in: visionImage, width: imageWidth, height: imageHeight) // 얼굴인식을 위한 함수
        
        CVPixelBufferUnlockBaseAddress(cvimgRef, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    private func detectFacesOnDevice(in image: VisionImage, width: CGFloat, height: CGFloat) {
        
        var faces: [Face]
        
        let options = FaceDetectorOptions()
        options.landmarkMode = .none
        options.contourMode = .all
        options.classificationMode = .none
        options.performanceMode = .fast
        
        let faceDetector = FaceDetector.faceDetector(options: options)
        
        do {
            faces = try faceDetector.results(in: image)
        } catch let error {
            print("Failed to detect faces with error: \(error.localizedDescription).")
            self.updatePreviewOverlayViewWithLastFrame()
            return
        }
        
        self.updatePreviewOverlayViewWithLastFrame()
        
        guard !faces.isEmpty else { return print("On-Device face detector returned no results.") }
        
        DispatchQueue.main.sync {
            
            for face in faces {
                
                let x = (face.frame.origin.x + face.frame.size.width * 0.35),
                    y = (face.frame.origin.y + face.frame.size.height * 0.2),
                    w = (face.frame.size.width) * 0.4,
                    h = (face.frame.size.height) * 0.62 // 얼굴인식 위치 설정
                
                let normalizedRect = CGRect(x: (x / width) * 1.3,
                                            y: y / height,
                                            width: w / width,
                                            height: h / height)
                
                let standardizedRect = self.previewLayer.layerRectConverted(fromMetadataOutputRect: normalizedRect).standardized
                
                if ((self.detectionArea.frame.minX * 0.8) <= standardizedRect.minX),
                   ((self.detectionArea.frame.maxX * 1.2) >= standardizedRect.maxX),
                   ((self.detectionArea.frame.minY * 0.8) <= standardizedRect.minY),
                   ((self.detectionArea.frame.maxY * 1.2) >= standardizedRect.maxY) {
                    
//                    self.detectionArea.layer.strokeColor = UIColor.white.cgColor
                    self.cropFaceRect = CGRect(x: x, y: y, width: w, height: h).integral // 얼굴인식 위치 계산
                } else {
//                    self.detectionArea.layer.strokeColor = UIColor.red.cgColor
                    self.flag = false
                    self.cropFaceRect = nil
                }
            }
        }
    }
    
    private func updatePreviewOverlayViewWithLastFrame() {
        DispatchQueue.main.sync {
            guard let lastFrame = lastFrame,
                  let imageBuffer = CMSampleBufferGetImageBuffer(lastFrame) else { return }
            
            self.updatePreviewOverlayViewWithImageBuffer(imageBuffer)
        }
    }
    
    private func updatePreviewOverlayViewWithImageBuffer(_ imageBuffer: CVImageBuffer?) {
        if let faceRect = self.cropFaceRect {
            guard let lastFrame = self.lastFrame,
                  let faceCropBuffer = self.croppedSampleBuffer(lastFrame, with: faceRect) else { return }
            
            self.extractRGBFromDetectFace(sampleBuffer: faceCropBuffer) //얼굴이미지에서 rgb데이터 추출을 위한
            
                /// 데이터 수집 완료, 수집개수로만 처리시 error 발생 ; 방지를 위해 flag사용
            if self.flag && (self.dataModel.gData.count == self.model.measurementTime * self.preparingSec) {
                self.collectDatas()
            }
        } else {
            self.detectTimer.invalidate()
            self.rgbModel.initRGBData()
            self.flag = true
        }
    }
    
        // MARK: Detect
    private func extractRGBFromDetectFace(sampleBuffer: CMSampleBuffer) {
        guard let faceRGB = OpenCVWrapper.detectFace(sampleBuffer) else { return print("objc casting error") }
        
        guard let r = faceRGB[0] as? Float,
              let g = faceRGB[1] as? Float,
              let b = faceRGB[2] as? Float else { return print("objc rgb casting error") }
        
        let timeStamp = (Date().timeIntervalSince1970 * 1000000).rounded()
        let numberOfData = self.viewModel.numberOfData,
            filteredData = self.viewModel.filteredData
        
        self.rgbModel.collectRGB(timeStamp: timeStamp, r: r, g: g, b: b) //rgb데이터 수집
        numberOfData.onNext(self.dataModel.gData.count)
        filteredData.onNext(self.filter(g: self.dataModel.gData))
    }
    
    private func filter(g: [Float]) -> Double {
        let a = [1.0, -7.30103128, 23.42566938, -43.14485924, 49.89209273, -37.09502293, 17.31790014, -4.64159393, 0.54684548]
        let b = [0.00013253, 0.0, -0.00053013, 0.0, 0.0007952, 0.0, -0.00053013, 0.0, 0.00013253]
        
        var x: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        var y: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        var result = Double()
        
        for i in g.indices {
            x.insert(Double(g[i]), at: 0)
            
            result = ((b[0] * x[0])
                      + (b[1] * x[1])
                      + (b[2] * x[2])
                      + (b[3] * x[3])
                      + (b[4] * x[4])
                      + (b[5] * x[5])
                      + (b[6] * x[6])
                      + (b[7] * x[7])
                      + (b[8] * x[8])
                      - (a[1] * y[0])
                      - (a[2] * y[1])
                      - (a[3] * y[2])
                      - (a[4] * y[3])
                      - (a[5] * y[4])
                      - (a[6] * y[5])
                      - (a[7] * y[6])
                      - (a[8] * y[7]))
            
            y.insert(result, at: 0)
            x.removeLast()
            y.removeLast()
        }
        return result
    }
    
        // MARK: ImageBuffer crop
    private func croppedSampleBuffer(_ sampleBuffer: CMSampleBuffer, with rect: CGRect) -> CMSampleBuffer? { // 특정 사이즈만큼 화면을 잘라 카메라 측정을 하기 위한 함수
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let bytesPerPixel = bytesPerRow / width
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return nil }
        let baseAddressStart = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        var cropX = Int(rect.origin.x)
        let cropY = Int(rect.origin.y)
        
            // Start pixel in RGB color space can't be odd.
        if cropX % 2 != 0 {
            cropX += 1
        }
        
        let cropStartOffset = Int(cropY * bytesPerRow + cropX * bytesPerPixel)
        
        var pixelBuffer: CVPixelBuffer!
        var error: CVReturn
        
            // Initiates pixelBuffer.
        let pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer)
        let options = [kCVPixelBufferCGImageCompatibilityKey: true,
               kCVPixelBufferCGBitmapContextCompatibilityKey: true,
                                      kCVPixelBufferWidthKey: rect.size.width,
                                     kCVPixelBufferHeightKey: rect.size.height] as [CFString : Any]
        
        error = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                             Int(rect.size.width),
                                             Int(rect.size.height),
                                             pixelFormat,
                                             &baseAddressStart[cropStartOffset],
                                             Int(bytesPerRow),
                                             nil,
                                             nil,
                                             options as CFDictionary,
                                             &pixelBuffer)
        if error != kCVReturnSuccess {
            print("Crop CVPixelBufferCreateWithBytes error \(Int(error))")
            return nil
        }
        
            // Cropping using CIImage.
        var ciImage = CIImage(cvImageBuffer: imageBuffer)
        ciImage = ciImage.cropped(to: rect)
            // CIImage is not in the original point after cropping. So we need to pan.
        ciImage = ciImage.transformed(by: CGAffineTransform(translationX: CGFloat(-cropX), y: CGFloat(-cropY)))
        
        guard let pixelBuffer = pixelBuffer else { return nil }
        
        self.gCIContext?.render(ciImage, to: pixelBuffer)
        
            // Prepares sample timing info.
        var sampleTime = CMSampleTimingInfo()
        sampleTime.duration = CMSampleBufferGetDuration(sampleBuffer)
        sampleTime.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        sampleTime.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
        
        var videoInfo: CMVideoFormatDescription!
        error = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                             imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
        if error != kCVReturnSuccess {
            print("CMVideoFormatDescriptionCreateForImageBuffer error \(Int(error))")
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
            return nil
        }
        
            // Creates `CMSampleBufferRef`.
        var resultBuffer: CMSampleBuffer?
        error = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                   imageBuffer: pixelBuffer,
                                                   dataReady: true,
                                                   makeDataReadyCallback: nil,
                                                   refcon: nil,
                                                   formatDescription: videoInfo,
                                                   sampleTiming: &sampleTime,
                                                   sampleBufferOut: &resultBuffer)
        if error != kCVReturnSuccess {
            print("CMSampleBufferCreateForImageBuffer error \(Int(error))")
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        return resultBuffer
    }
    
    private func imageOrientation(fromDevicePosition devicePosition: AVCaptureDevice.Position = .back) -> UIImage.Orientation {
        
        var deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .faceDown || deviceOrientation == .faceUp || deviceOrientation == .unknown{
            deviceOrientation = self.currentUIOrientation()
        }
        switch deviceOrientation {
            case .portrait:
                return devicePosition == .front ? .leftMirrored : .right
            case .landscapeLeft:
                return devicePosition == .front ? .downMirrored : .up
            case .portraitUpsideDown:
                return devicePosition == .front ? .rightMirrored : .left
            case .landscapeRight:
                return devicePosition == .front ? .upMirrored : .down
            case .faceDown, .faceUp, .unknown:
                return .up
            @unknown default:
                fatalError()
        }
    }
    
    private func currentUIOrientation() -> UIDeviceOrientation {
        let deviceOrientation = { () -> UIDeviceOrientation in
            switch UIApplication.shared.statusBarOrientation {
                case .landscapeLeft:
                    return .landscapeRight
                case .landscapeRight:
                    return .landscapeLeft
                case .portraitUpsideDown:
                    return .portraitUpsideDown
                case .portrait, .unknown:
                    return .portrait
                @unknown default:
                    fatalError()
            }
        }
        
        guard Thread.isMainThread else {
            var currentOrientation: UIDeviceOrientation = .portrait
            DispatchQueue.main.sync {
                currentOrientation = deviceOrientation()
            }
            return currentOrientation
        }
        return deviceOrientation()
    }
}
