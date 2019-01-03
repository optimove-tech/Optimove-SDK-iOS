Pod::Spec.new do |s|
  s.name             = 'OptimoveSDK'
  s.version          = '1.3.0'
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
  s.swift_version = '4.2'
  s.source_files = 'OptimoveSDK/Classes/**/*'
  
  s.dependency 'Firebase/Core', '5.15.0'
  s.dependency 'FirebaseAnalytics', '5.4.0'
  s.dependency 'FirebaseAnalyticsInterop', '1.1.0'
  s.dependency 'FirebaseCore', '5.1.10'
  s.dependency 'FirebaseDynamicLinks', '3.3.0'
  s.dependency 'FirebaseInstanceID', '3.3.0'
  s.dependency 'FirebaseMessaging', '3.2.2'
  s.dependency 'GoogleAppMeasurement', '5.4.0'
  s.dependency 'GoogleUtilities', '5.3.6'
  s.dependency 'Protobuf', '3.6.1'
  s.dependency 'nanopb', '0.3.901'
  s.dependency 'OptiTrackCore', '1.3.0'
  # s.dependency 'XCGLogger', '6.1.0'
  
  
  
 
  s.frameworks = 'UIKit','SystemConfiguration','UserNotifications','AdSupport'
end
