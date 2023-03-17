#ifdef __cplusplus
#undef NO
#undef YES
#import <opencv2/opencv.hpp>
#endif
#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#if defined(NO)
#  warning Detected Apple 'NO' macro definition, it can cause build conflicts. Please, include this header before any Apple headers.
#endif

#import "ObjcMapper.h"
#import "OpenCVWrapper.h"

FOUNDATION_EXPORT double DeepmediFaceKitVersionNumber;
FOUNDATION_EXPORT const unsigned char DeepmediFaceKitVersionString[];

