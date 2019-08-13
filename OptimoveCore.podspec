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
  base_dir = "OptimoveCore/"
  s.source_files = base_dir + 'Classes/**/*'
  s.frameworks = 'Foundation'
  s.test_spec do |unit_tests|
    unit_tests.source_files = base_dir + 'Tests/Sources/**/*'
    unit_tests.resources = base_dir + 'Tests/Resources/**/*'
  end
end
