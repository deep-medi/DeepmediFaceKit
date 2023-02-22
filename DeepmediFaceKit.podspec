#
# Be sure to run `pod lib lint DeepmediFaceKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DeepmediFaceKit'
  s.version          = '0.5.3'
  s.summary          = 'Framework for measurement after face recognition'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/deep-medi/DeepmediFaceKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'demianjun' => 'demianjun@gmail.com' }
  s.source           = { :git => 'https://github.com/deep-medi/DeepmediFaceKit.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'

#  s.source_files = 'DeepmediFaceKit','DeepmediFaceKit/Classes/**/*.{h,m,swift}'
  s.source_files = 'DeepmediFaceKit','DeepmediFaceKit/Classes/**/*.{h,swift}', 'DeepmediFaceKit/Objc/*.{h,mm}'
  
  s.swift_versions = '5.0'
  s.static_framework = true
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  # s.resource_bundles = {
  #   'DeepmediFaceKit' => ['DeepmediFaceKit/Assets/*.png']
  # }₩

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.dependency 'Then'
  s.dependency 'SnapKit', '~> 5.0.0'
  s.dependency 'GoogleMLKit/FaceDetection'
  s.dependency 'Alamofire', '~> 5.2.0'
  s.dependency 'OpenCV'
  s.dependency 'RxSwift', '~> 6.0.0'
  s.dependency 'RxCocoa', '~> 6.0.0'

end
