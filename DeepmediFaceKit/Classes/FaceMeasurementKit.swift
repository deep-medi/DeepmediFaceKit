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

public class FaceMeasureKit: NSObject {
    private let bag = DisposeBag()
    
    private let makeDocument = Document(),
                rgbModel = RGBData(),
                viewModel = ViewModel()
    
    private let dataModel = DataModel.shared,
                model = Model.shared
    
    private var lastFrame: CMSampleBuffer?,
                gCIContext: CIContext?,
                cropFaceRect: CGRect?,
                cropChestRect: CGRect?
    
        // MARK: Property
    private var flag = false,
                sec = Double(), // 측정하는 시간
                preparingSec = Int(), // 얼굴을 인식하고 준비하는 시간
                detectTimer = Timer()
    
    private var previewLayer = AVCaptureVideoPreviewLayer(),
                faceRecognitionAreaView = UIView()
    
    public func finishedMeasurement(
        _ isSuccess: @escaping((Bool, URL?) -> ())
    ) {
        let completion = self.viewModel.completeMeasurement
        completion
            .asDriver(onErrorJustReturn: (false, URL(string: "")))
            .drive(onNext: { result in
                isSuccess(result.0, result.1)
            })
            .disposed(by: bag)
    }
    
    public func measurementCompleteRatio(
        _ com: @escaping((String) -> ())
    ) {
        let ratio = self.viewModel.measurementCompleteRatio
        ratio
            .asDriver(onErrorJustReturn: "0%")
            .asDriver()
            .drive(onNext: { ratio in
                com(ratio)
            })
            .disposed(by: self.bag)
    }

    public func timesLeft(
        _ com: @escaping((Double) -> ())
    ) {
        let secondRemaining = self.viewModel.secondRemaining
        secondRemaining
            .asDriver(onErrorJustReturn: 0.0)
            .drive(onNext: { remaining in
                com(remaining)
            })
            .disposed(by: bag)
    }

    public override init() {
        super.init()
        UIApplication.shared.isIdleTimerDisabled = true //측정중 화면 자동잠금을 막기 위해 설정
        self.previewLayer = self.model.previewLayer
        self.faceRecognitionAreaView = self.model.faceRecognitionAreaView
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
            secondRemaining = self.viewModel.secondRemaining,
            measurementCompleteRatio = self.viewModel.measurementCompleteRatio

        self.rgbModel.initRGBData() // 중간에 쌓여있을 수 있는 데이터 초기화

        self.flag = false
        self.sec = self.model.measurementTime
        self.preparingSec = 1
        self.detectTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1, repeats: true
        ) { timer in
            secondRemaining.onNext(self.sec)
            measurementCompleteRatio.onNext("\(100 - Int(self.sec * 100.0 / 30.0))%")
            self.sec -= 0.1
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
extension FaceMeasureKit: AVCaptureVideoDataOutputSampleBufferDelegate { // 카메라 이미지에서 데이터 수집을 위한 delegate
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let cvimgRef: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { fatalError("cvimg ref") }

        CVPixelBufferLockBaseAddress(cvimgRef, CVPixelBufferLockFlags(rawValue: 0))

        self.lastFrame = sampleBuffer

        let orientation = self.imageOrientation(fromDevicePosition: .front)
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = orientation

        let imageWidth = CGFloat(CVPixelBufferGetWidth(cvimgRef))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(cvimgRef))

        self.detectFacesOnDevice(
            in: visionImage,
            imageWidth: imageWidth,
            imageHeight: imageHeight
        ) // 얼굴인식을 위한 함수

        CVPixelBufferUnlockBaseAddress(cvimgRef, CVPixelBufferLockFlags(rawValue: 0))
    }

    private func detectFacesOnDevice(
        in image: VisionImage,
        imageWidth: CGFloat,
        imageHeight: CGFloat
    ) {

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
            return
        }

        self.updatePreviewOverlayViewWithLastFrame()

        guard !faces.isEmpty else {
            self.flag = false
            self.cropFaceRect = nil
            print("On-Device face detector returned no results.")
            return
        }

        DispatchQueue.main.sync {

            for face in faces {

                let x = (face.frame.origin.x + face.frame.size.width * 0.35),
                    y = (face.frame.origin.y + face.frame.size.height * 0.2),
                    w = (face.frame.size.width) * 0.4,
                    h = (face.frame.size.height) * 0.62 // 얼굴인식 위치 설정

                let normalizedRect = CGRect(x: x / imageWidth,
                                            y: y / imageHeight,
                                            width: w / imageWidth,
                                            height: h / imageHeight)
               
                if self.model.useFaceRecognitionArea {
                    self.recognitionArea(
                        face: face,
                        imageWidth: imageWidth,
                        imageHeight: imageHeight,
                        normalizedRect: normalizedRect,
                        faceRecognitionAreaView: faceRecognitionAreaView
                    )
                } else {
                    self.noneRecognitionArea(
                        face: face,
                        imageWidth: imageWidth,
                        imageHeight: imageHeight,
                        normalizedRect: normalizedRect
                    )
                }
            }
        }
    }
    
    private func recognitionArea(
        face: Face,
        imageWidth: CGFloat,
        imageHeight: CGFloat,
        normalizedRect: CGRect,
        faceRecognitionAreaView: UIView
    ) {
        let standardizedRect = self.previewLayer.layerRectConverted(fromMetadataOutputRect: normalizedRect).standardized
        
        if (faceRecognitionAreaView.frame.minX <= standardizedRect.minX) &&
           (faceRecognitionAreaView.frame.maxX >= standardizedRect.maxX) &&
           (faceRecognitionAreaView.frame.minY <= standardizedRect.minY) &&
           (faceRecognitionAreaView.frame.maxY >= standardizedRect.maxY) {

            self.cropFaceRect = CGRect(x: normalizedRect.origin.x,
                                       y: normalizedRect.origin.y,
                                       width: normalizedRect.width,
                                       height: normalizedRect.height).integral // 얼굴인식 위치 계산
            self.addContours(
                for: face,
                imageWidth: imageWidth,
                imageHeight: imageHeight
            )
            
        } else {
            
            self.flag = false
            self.cropFaceRect = nil
        }
    }
    
    private func noneRecognitionArea(
        face: Face,
        imageWidth: CGFloat,
        imageHeight: CGFloat,
        normalizedRect: CGRect
    ) {
        self.cropFaceRect = CGRect(x: normalizedRect.origin.x,
                                   y: normalizedRect.origin.y,
                                   width: normalizedRect.width,
                                   height: normalizedRect.height).integral // 얼굴인식 위치 계산
        self.addContours(
            for: face,
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )
    }

    private func updatePreviewOverlayViewWithLastFrame() {
        DispatchQueue.main.sync {
            guard lastFrame != nil else { fatalError("sample buffer error") }
            self.updatePreviewOverlayViewWithImageBuffer()
        }
    }

    private func updatePreviewOverlayViewWithImageBuffer() {
        if self.cropFaceRect != nil {
            if self.dataModel.gData.count == self.preparingSec * 30 && self.flag {
                CameraObject().AELock()
                self.collectDatas()
            }
        } else {
            self.detectTimer.invalidate()
            self.rgbModel.initRGBData()
            self.flag = true
        }
    }

        // MARK: Detect
    private func extractRGBFromDetectFace(
        sampleBuffer: CMSampleBuffer
    ) {
        guard let faceRGB = OpenCVWrapper.detectFace(sampleBuffer) else {
            print("objc casting error")
            return
        }

        guard let r = faceRGB[0] as? Float,
              let g = faceRGB[1] as? Float,
              let b = faceRGB[2] as? Float else {
            print("objc rgb casting error")
            return
        }

        let timeStamp = (Date().timeIntervalSince1970 * 1000000).rounded()
        self.rgbModel.collectRGB(
            timeStamp: timeStamp,
            r: r, g: g, b: b
        ) //rgb데이터 수집
    }

    private func addContours(
        for face: Face,
        imageWidth: CGFloat,
        imageHeight: CGFloat
    ) {
        if let rect = self.cropFaceRect,
           let lastFrame = self.lastFrame,
           let faceContour = face.contour(ofType: .face),
           let leftEyeContour = face.contour(ofType: .leftEye),
           let leftEyeBrowTopContour = face.contour(ofType: .leftEyebrowTop),
           let leftEyeBrowBottomContour = face.contour(ofType: .leftEyebrowBottom),
           let rightEyeContour = face.contour(ofType: .rightEye),
           let rightEyeBrowTopContour = face.contour(ofType: .rightEyebrowTop),
           let rightEyeBrowBottomContour = face.contour(ofType: .rightEyebrowBottom),
           let upperLipContour = face.contour(ofType: .upperLipTop),
           let lowerLipContour = face.contour(ofType: .lowerLipBottom),
           let faceCropBuffer = self.croppedSampleBuffer(lastFrame, with: rect),
           let cropImage = OpenCVWrapper.converting(faceCropBuffer) {

            var facePath = UIBezierPath().then { p in
                p.lineWidth = 2
            }
            var leftEyePath = UIBezierPath().then { p in
                p.lineWidth = 2
            }
            var rightEyePath = UIBezierPath().then { p in
                p.lineWidth = 2
            }
            var leftEyeBrowPath = UIBezierPath().then { p in
                p.lineWidth = 2
            }
            var rightEyeBrowPath = UIBezierPath().then { p in
                p.lineWidth = 2
            }
            var lipsPath = UIBezierPath().then { p in
                p.lineWidth = 2
            }

            draw(
                previewLayer: previewLayer,
                facePoints: faceContour.points,
                leftEyePoints: leftEyeContour.points,
                rightEyePoints: rightEyeContour.points,
                leftEyeBrowPoints: leftEyeBrowTopContour.points + leftEyeBrowBottomContour.points ,
                rightEyeBrowPoints: rightEyeBrowTopContour.points + rightEyeBrowBottomContour.points,
                lipsPoints: upperLipContour.points + lowerLipContour.points,
                cropImage: cropImage,
                imageWidth: imageWidth,
                imageHeight: imageHeight
            )

            func draw(
                previewLayer: AVCaptureVideoPreviewLayer?,
                facePoints: [VisionPoint],
                leftEyePoints: [VisionPoint],
                rightEyePoints: [VisionPoint],
                leftEyeBrowPoints: [VisionPoint],
                rightEyeBrowPoints: [VisionPoint],
                lipsPoints: [VisionPoint],
                cropImage: UIImage?,
                imageWidth: CGFloat,
                imageHeight: CGFloat
            ) {

                facePath.lineJoinStyle = .miter

                guard let previewLayer = previewLayer,
                      let cropImage = cropImage else { return print("crop image return") }

                gridPath(
                    previewLayer: previewLayer,
                    width: imageWidth,
                    height: imageHeight,
                    points: facePoints,
                    path: &facePath
                )
                
                gridPath(
                    previewLayer: previewLayer,
                    width: imageWidth,
                    height: imageHeight,
                    points: leftEyePoints,
                    path: &leftEyePath
                )
                gridPath(
                    previewLayer: previewLayer,
                    width: imageWidth,
                    height: imageHeight,
                    points: rightEyePoints,
                    path: &rightEyePath
                )
                
                gridPath(
                    previewLayer: previewLayer,
                    width: imageWidth,
                    height: imageHeight,
                    points: leftEyeBrowPoints,
                    path: &leftEyeBrowPath
                )
                gridPath(
                    previewLayer: previewLayer,
                    width: imageWidth,
                    height: imageHeight,
                    points: rightEyeBrowPoints,
                    path: &rightEyeBrowPath
                )
                
                gridPath(
                    previewLayer: previewLayer,
                    width: imageWidth,
                    height: imageHeight,
                    points: lipsPoints,
                    path: &lipsPath
                )

                facePath.append(leftEyePath)
                facePath.append(rightEyePath)
                facePath.append(leftEyeBrowPath)
                facePath.append(rightEyeBrowPath)
                facePath.append(lipsPath)

                guard let faceCropImage = getMaskedImage(picture: cropImage, cgPath: facePath.cgPath),
                      let sampleBuffer = faceCropImage.createCMSampleBuffer() else { fatalError("face crop image return") }

                self.extractRGBFromDetectFace(sampleBuffer: sampleBuffer)
            }
        }
    }

    private func normalizedPoint(
      fromVisionPoint point: VisionPoint,
      width: CGFloat,
      height: CGFloat
    ) -> CGPoint {
      let cgPoint = CGPoint(x: point.x, y: point.y)
      var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
      normalizedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
      return normalizedPoint
    }

    private func getMaskedImage(
        picture: UIImage,
        cgPath: CGPath
    ) -> UIImage? {
        let picture = flipImage(picture) ?? picture
        let imageLayer = CALayer()
        imageLayer.frame = CGRect(origin: .zero, size: picture.size)
        imageLayer.contents = picture.cgImage
        let maskLayer = CAShapeLayer()
        let maskPath = cgPath.resized(to: CGRect(origin: .zero, size: picture.size))
        maskLayer.path = maskPath
        maskLayer.fillRule = .evenOdd
        imageLayer.mask = maskLayer

        UIGraphicsBeginImageContext(picture.size)
        defer { UIGraphicsEndImageContext() }

        if let context = UIGraphicsGetCurrentContext() {
            context.addPath(maskPath ?? cgPath)
            context.clip()
            imageLayer.render(in: context)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()

            return newImage
        }
        return nil
    }

    private func normalizedPoint(
        previewLayer: AVCaptureVideoPreviewLayer,
        fromVisionPoint point: VisionPoint,
        width: CGFloat,
        height: CGFloat
    ) -> CGPoint {
        let cgPoint = CGPoint(x: point.x, y: point.y)
        var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
        normalizedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
        return normalizedPoint
    }

    private func gridPath(
        previewLayer: AVCaptureVideoPreviewLayer,
        width: CGFloat,
        height: CGFloat,
        points: [VisionPoint],
        path: inout UIBezierPath
    ) {
        for (i, point) in points.enumerated() {
            let cgPoint = normalizedPoint(previewLayer: previewLayer,
                                          fromVisionPoint: point,
                                          width: width,
                                          height: height)
            if i == 0 {
                path.move(to: CGPoint(x: cgPoint.x, y: cgPoint.y))
            } else if i == points.count - 1 {
                path.addLine(to: CGPoint(x: cgPoint.x, y: cgPoint.y))
                path.close()
                path.stroke()
            } else {
                path.addLine(to: CGPoint(x: cgPoint.x, y: cgPoint.y))
            }
        }
    }

    private func flipImage(
        _ image: UIImage
    ) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: image.size.width, y: image.size.height)
        context.scaleBy(x: -image.scale, y: -image.scale)
        context.draw(image.cgImage!, in: CGRect(origin:CGPoint.zero, size: image.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

        // MARK: ImageBuffer crop
    private func croppedSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with rect: CGRect
    ) -> CMSampleBuffer? { // 특정 사이즈만큼 화면을 잘라 카메라 측정을 하기 위한 함수

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

    private func imageOrientation(
        fromDevicePosition devicePosition: AVCaptureDevice.Position = .back
    ) -> UIImage.Orientation {

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
