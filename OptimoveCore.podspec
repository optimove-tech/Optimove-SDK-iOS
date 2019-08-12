Pod::Spec.new do |s|
  s.name             = 'OptimoveCore'
  s.version          = '0.1.0'
  s.summary          = 'Official Optimove SDK for iOS to access Optimove core features.'
  s.description      = <<-DESC
The Optimove SDK for iOS Core framework provides:
                   * Core Events
                       DESC
  s.homepage         = 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mobius Solutions' => 'mobile@optimove.com' }
  s.source           = { :git => 'https://github.com/optimove-tech/iOS-SDK-Integration-Guide.git', :tag => 'Core-' + s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5'
  s.source_files = 'OptimoveCore/Classes/**/*'
  s.frameworks = 'Foundation'
end
