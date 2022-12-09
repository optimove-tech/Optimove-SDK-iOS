Pod::Spec.new do |s|
  s.name             = 'OptimoveCore'
  s.version          = '5.2.0'
  s.summary          = 'Official Optimove SDK for iOS. Core framework.'
  s.description      = 'The core framework is used to share code-base between other Optimove frameworks.'
  s.homepage         = 'https://github.com/optimove-tech/Optimove-SDK-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mobius Solutions' => 'mobile@optimove.com' }
  s.source           = { :git => 'https://github.com/optimove-tech/Optimove-SDK-iOS.git', :tag => s.version.to_s }
  s.platform = 'ios'
  s.ios.deployment_target = '10.0'
  s.swift_version = '5'
  base_dir = "OptimoveCore/"
  s.source_files = base_dir + 'Sources/Classes/**/*'
  s.frameworks = 'Foundation'
  s.test_spec 'unit' do |unit_tests|
    unit_tests.source_files = base_dir + 'Tests/Sources/**/*', 'Shared/Tests/Sources/**/*'
    unit_tests.resources = base_dir + 'Tests/Resources/**/*', 'Shared/Tests/Resources/**/*'
    unit_tests.dependency 'Mocker', '~> 1.0'
  end
end
