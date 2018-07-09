Pod::Spec.new do |s|
  s.name             = 'OptimoveSDK'
  s.version          = '1.2.0'
  s.summary          = 'Optimove SDK for Analytics and push notifications.'

  s.description      = <<-DESC
  This Pod includes the Optimove framework for reporting events and receive optimove push notifications
                       DESC

  s.homepage         = 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'optimove mobile developer' => 'optimove.develop.mobile@gmail.com' }
  s.source           = { :git => 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Optimove'
  
  
  s.ios.deployment_target = '10.0'
  s.static_framework = true
  s.swift_version = '4.1'
  s.source_files = 'OptimoveSDK/Classes/**/*'
  s.dependency 'Firebase/Core', '~> 5.4.0'
  s.dependency 'Firebase/Messaging'
  s.dependency 'Firebase/DynamicLinks'
  s.dependency 'OptiTrackCore'
  s.dependency 'XCGLogger','~> 6.0.4'
  
 
  # s.frameworks = 'UIKit', 'MapKit'
end
