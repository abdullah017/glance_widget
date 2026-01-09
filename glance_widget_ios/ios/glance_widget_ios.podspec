Pod::Spec.new do |s|
  s.name             = 'glance_widget_ios'
  s.version          = '0.1.0'
  s.summary          = 'iOS implementation of the glance_widget plugin using WidgetKit.'
  s.description      = <<-DESC
iOS implementation of the glance_widget plugin that provides home screen widgets
using Apple's WidgetKit framework with SwiftUI. Supports Simple, Progress, and
List widget templates with instant updates when the app is in foreground.
                       DESC
  s.homepage         = 'https://github.com/abdullah017/glance_widget'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Abdullah Tas' => 'abdullah@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '16.0'
  s.swift_version    = '5.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # Privacy manifest for iOS 17+
  s.resource_bundles = {
    'glance_widget_ios_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
end
