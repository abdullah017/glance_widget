#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint glance_widget_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'glance_widget_ios'
  s.version          = '1.0.0'
  s.summary          = 'iOS implementation of the glance_widget plugin using WidgetKit.'
  s.description      = <<-DESC
iOS implementation of the glance_widget plugin that provides home screen widgets
using Apple's WidgetKit framework with SwiftUI. Supports Simple, Progress, and
List widget templates with instant updates when the app is in foreground.
                       DESC
  s.homepage         = 'https://github.com/abdullahtas0/glance_widget'
  s.license          = { :file => '../LICENSE' }
  # Contact runs through the issue tracker on the homepage above rather than a
  # personal mailbox.
  s.author           = 'Abdullah Tas'
  s.source           = { :path => '.' }
  # Laid out for Swift Package Manager; CocoaPods reads the same sources so both
  # dependency managers stay in sync from one copy of the code.
  s.source_files     = 'glance_widget_ios/Sources/glance_widget_ios/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '16.0'
  s.swift_version    = '5.9'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # This plugin reads and writes App Group `UserDefaults`, a required-reason API,
  # so the privacy manifest ships on every install.
  s.resource_bundles = {
    'glance_widget_ios_privacy' => ['glance_widget_ios/Sources/glance_widget_ios/PrivacyInfo.xcprivacy']
  }
end
