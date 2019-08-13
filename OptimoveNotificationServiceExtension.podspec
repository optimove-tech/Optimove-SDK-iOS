Pod::Spec.new do |s|
  s.name             = 'OptimoveNotificationServiceExtension'
  s.version          = '2.3.0'
  s.summary          = 'A notification service extension framework for Optimove SDK'
  s.description      = <<-DESC
The Notification service extension for Optimove SDK framework provides:
                  * handle notifications
                       DESC
  s.homepage         = 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mobius Solutions' => 'mobile@optimove.com' }
  s.source           = { :git => 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5'
  base_dir = "OptimoveNotificationServiceExtension/"
  s.source_files = base_dir + 'Classes/**/*'
  s.dependency 'OptimoveCore'
  s.frameworks = 'UserNotifications', 'UIKit'
  s.test_spec do |unit_tests|
    unit_tests.source_files = base_dir + 'Tests/Sources/**/*'
    unit_tests.resources = base_dir + 'Tests/Resources/**/*'
  end
end
