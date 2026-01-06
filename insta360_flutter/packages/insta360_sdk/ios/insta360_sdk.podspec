#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint insta360_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'insta360_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Flutter bindings for Insta360 iOS SDK.'
  s.description      = <<-DESC
Flutter bindings for Insta360 iOS SDK.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  frameworks_root = 'Frameworks'
  s.vendored_frameworks = [
    "#{frameworks_root}/INSCameraSDK.xcframework",
    "#{frameworks_root}/INSCameraServiceSDK.xcframework",
    "#{frameworks_root}/INSCoreMedia.xcframework",
    "#{frameworks_root}/SSZipArchive.xcframework",
    "#{frameworks_root}/SnapKit.xcframework",
    "#{frameworks_root}/Eureka.xcframework"
  ]
  s.frameworks = [
    'UIKit',
    'AVFoundation',
    'CoreBluetooth',
    'ExternalAccessory',
    'CoreMotion',
    'CoreMedia',
    'CoreVideo',
    'CoreGraphics',
    'GLKit'
  ]
  s.libraries = 'c++'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
    'FRAMEWORK_SEARCH_PATHS' => '"$(inherited)" "$(PODS_TARGET_SRCROOT)/Frameworks" "$(PODS_XCFRAMEWORKS_BUILD_DIR)/insta360_sdk"',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) TO_B_SDK=1'
  }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'insta360_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
