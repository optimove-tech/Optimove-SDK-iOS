Pod::Spec.new do |s|
  s.name             = 'OptimoveSDK'
  s.version          = '2.1.2'
  s.summary          = 'Optimove SDK for Analytics and push notifications.'

  s.description      = <<-DESC
  This Pod includes the Optimove framework for reporting events and receive optimove push notifications
                       DESC

  s.homepage         = 'https://github.com/optimove-tech/Mobile-SDK-Integration-Guide/tree/master/iOS Integration Guide'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mobius Solutions' => 'mobile@optimove.com' }
  s.source           = { :git => 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Optimove'
  
  
  s.ios.deployment_target = '10.0'
  s.static_framework = true
  s.swift_version = '4.2'
  s.source_files = 'OptimoveSDK/Classes/**/*'
  

  s.dependency 'FirebaseDynamicLinks', '4.0.0'
  s.dependency 'FirebaseMessaging', '4.0.2'
  s.dependency 'OptiTrackCore', '1.3.1'
  
  s.frameworks = 'UIKit','SystemConfiguration','UserNotifications','AdSupport'
end
