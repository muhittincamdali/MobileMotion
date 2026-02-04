Pod::Spec.new do |s|
  s.name             = 'MobileMotion'
  s.version          = '1.0.0'
  s.summary          = 'Motion and sensor management framework for iOS.'
  s.description      = <<-DESC
    MobileMotion provides easy-to-use motion and sensor management for iOS.
    Features include accelerometer, gyroscope, magnetometer, and device motion
    with real-time updates and gesture recognition.
  DESC

  s.homepage         = 'https://github.com/muhittincamdali/MobileMotion'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Muhittin Camdali' => 'contact@muhittincamdali.com' }
  s.source           = { :git => 'https://github.com/muhittincamdali/MobileMotion.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.watchos.deployment_target = '8.0'

  s.swift_versions = ['5.9', '5.10', '6.0']
  s.source_files = 'Sources/**/*.swift'
  s.frameworks = 'Foundation', 'CoreMotion'
end
