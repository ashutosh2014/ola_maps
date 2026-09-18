Pod::Spec.new do |s|
  s.name             = 'ola_maps'
  s.version          = '0.3.0'
  s.summary          = 'Ola Maps Flutter plugin for Android and iOS.'
  s.description      = <<-DESC
Flutter plugin wrapping the Ola Maps SDKs (Android Map SDK + iOS OlaMapCore / OlaMapService).
                       DESC
  s.homepage         = 'https://github.com/ashutosh2014/ola_maps'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ola_maps' => 'support@olamaps.io' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'OlaMapCore'
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
  s.resource_bundles = {
    'ola_maps_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
end
