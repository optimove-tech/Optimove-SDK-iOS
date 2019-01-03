#
# Be sure to run `pod lib lint OptimoveNotificationServiceExtension.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OptimoveNotificationServiceExtension'
  s.version          = '1.3.0'
  s.summary          = 'A notification extension framework for Optimove SDK applications'

  s.description      = <<-DESC
This framework is an addition for the main OptimoveSDK in order to handle notifications
                       DESC

  s.homepage         = 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'optimove.develop.mobile@gmail.com' => 'optimove.develop.mobile@gmail.com' }
  s.source           = { :git => 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide.git', :tag => s.version.to_s }
  

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.2'
  s.source_files = 'OptimoveNotificationServiceExtension/OptimoveNotificationServiceExtension/Classes/**/*'
  s.frameworks = 'UserNotifications', 'UIKit'
end
