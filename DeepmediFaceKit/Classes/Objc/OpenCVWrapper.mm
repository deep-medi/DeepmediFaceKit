//
//  OpenCVWrapper.m
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/09.
//

#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OpenCVWrapper()

@property (nonatomic) cv::Mat YY;
@property (nonatomic) cv::Mat Xmtx;
@property (nonatomic) cv::Mat Ymtx;
@property (nonatomic) cv::Mat Acoeff;
@property (nonatomic) cv::Mat Bcoeff;
@property (nonatomic) cv::Mat buff;

@end


@implementation OpenCVWrapper

+ (NSString *)openCVVersionString {
return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

+ (NSArray *)detectFaceSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  
  void* bufferAddress;
  size_t width;
  size_t height;
  size_t bytesPerRow;
  
  bufferAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
  width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
  height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
  bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
  unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
  
//  mBGR = cv::Mat((int)height, (int)width, CV_8UC3, bufferAddress, 0);
//  cv::cvtColor(mBGR, mBGR, cv::COLOR_BGR2RGB);
//  cv::Scalar bgr = cv::mean(mBGR);
  
//  float r = bgr.val[2],
//        g = bgr.val[1],
//        b = bgr.val[0];
  
  cv::Mat imgMat = cv::Mat((int)height, (int)width, CV_8UC4, pixel, CVPixelBufferGetBytesPerRow(imageBuffer));
  cv::cvtColor(imgMat, imgMat, cv::COLOR_BGR2RGB);
  cv::Scalar mRGB = cv::mean(imgMat);
  cv::rotate(imgMat, imgMat, cv::ROTATE_90_CLOCKWISE);

  float r = mRGB.val[0],
        g = mRGB.val[1],
        b = mRGB.val[2];

  CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
  
  NSMutableArray *rgb = [[NSMutableArray alloc] init];
  
  [rgb insertObject:[NSNumber numberWithFloat:r] atIndex:0];
  [rgb insertObject:[NSNumber numberWithFloat:g] atIndex:1];
  [rgb insertObject:[NSNumber numberWithFloat:b] atIndex:2];
  
  imgMat.release();
  
  return rgb;
}

+ (unsigned char *)detectChestSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  
  void* bufferAddress;
  size_t width;
  size_t height;
  size_t bytesPerRow;
  
  bufferAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
  width = CVPixelBufferGetWidth(imageBuffer);
  height = CVPixelBufferGetHeight(imageBuffer);
  bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
  unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
  
  cv::Mat imgMat = cv::Mat((int)height, (int)width, CV_8UC4, pixel, bytesPerRow);
  cv::resize(imgMat, imgMat, cv::Size(32, 32));
  cv::cvtColor(imgMat, imgMat, cv::COLOR_RGBA2GRAY); // BGRA2GRAY -> RGBA2GRAY 차이가 큼
  cv::rotate(imgMat, imgMat, cv::ROTATE_90_CLOCKWISE);

  unsigned long size = height * width;
  
  uint8_t *buf = new uint8_t[size];

  memcpy(buf, imgMat.data, size);
  
  CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
  imgMat.release();
  
  return buf;
}

+ (UIImage *)convertingBuffer:(CMSampleBufferRef)sampleBuffer {
  
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  
  size_t width;
  size_t height;
  size_t bytesPerRow;
  
  width = CVPixelBufferGetWidth(imageBuffer);
  height = CVPixelBufferGetHeight(imageBuffer);
  bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
  unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
  
  cv::Mat imgMat = cv::Mat((int)height, (int)width, CV_8UC4, pixel, bytesPerRow);
  cv::cvtColor(imgMat, imgMat, cv::COLOR_BGR2RGB);
  cv::rotate(imgMat, imgMat, cv::ROTATE_90_CLOCKWISE);

  UIImage* outcome = MatToUIImage(imgMat);
  
  CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
  
  imgMat.release();
  
  return outcome;
}

@end
