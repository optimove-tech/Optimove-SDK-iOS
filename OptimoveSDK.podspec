Pod::Spec.new do |s|
  s.name             = 'OptimoveSDK'
  s.version          = '2.2.10'
  s.summary          = 'Optimove SDK for Analytics and push notifications.'
  s.description      = 'This Pod includes the Optimove framework for reporting events and receive optimove push notifications'
  s.homepage         = 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mobius Solutions' => 'mobile@optimove.com' }
  s.source           = { :git => 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide.git', :tag => 'SDK-' + s.version.to_s }
  s.social_media_url = 'https://twitter.com/Optimove'
  s.platform = 'ios'
  s.ios.deployment_target = '10.0'
  s.static_framework = true
  s.swift_version = '5'
  base_dir = "OptimoveSDK/"
  s.source_files = base_dir +'Classes/**/*'
  s.dependency 'FirebaseMessaging', '~> 4.0'
  s.dependency 'MatomoTracker', '~> 6.0'
  s.dependency 'ReachabilitySwift', '~> 4.0'
  s.dependency 'OptimoveCore', '~> 2.0'
  s.frameworks = 'UIKit', 'SystemConfiguration', 'UserNotifications', 'AdSupport'
  s.test_spec 'unit' do |unit_tests|
    unit_tests.source_files = base_dir + 'Tests/Sources/**/*',  'Shared/Tests/Sources/**/*'
    unit_tests.resources = base_dir + 'Tests/Resources/**/*', 'Shared/Tests/Resources/**/*'
    unit_tests.dependency 'Mocker', '~> 1.0.0'
  end
end
