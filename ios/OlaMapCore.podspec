Pod::Spec.new do |spec|
  spec.name = 'OlaMapCore'
  spec.version = '1.0.8'
  spec.summary = 'OlaMap Core Service'
  spec.description = 'OlaMapService plus every xcframework OlaMapCore links at runtime (including MoEngageCards).'
  spec.homepage = 'https://maps.olakrutrim.com/'
  spec.author = { 'OlaMaps Team' => 'support@olamaps.io' }
  spec.license = { :type => 'Copyright', :text => 'Copyright Ola Maps' }
  spec.source = {
    :git => 'https://github.com/ola-maps/ios-map-sdk.git',
    :tag => '1.0.8',
  }
  spec.swift_version = '5.0'
  spec.ios.deployment_target = '13.0'

  # Upstream podspec omits Cards / InApps / TriggerEvaluator even though
  # OlaMapCore.framework is linked against them (@rpath). Device launch then
  # aborts in dyld. Vendor the full Frameworks/ tree from the git tag.
  spec.ios.vendored_frameworks = [
    'Frameworks/OlaMapCore.xcframework',
    'Frameworks/MapLibre.xcframework',
    'Frameworks/MoEngageAnalytics.xcframework',
    'Frameworks/MoEngageCards.xcframework',
    'Frameworks/MoEngageCore.xcframework',
    'Frameworks/MoEngageInApps.xcframework',
    'Frameworks/MoEngageMessaging.xcframework',
    'Frameworks/MoEngageObjCUtils.xcframework',
    'Frameworks/MoEngageSDK.xcframework',
    'Frameworks/MoEngageSecurity.xcframework',
    'Frameworks/MoEngageTriggerEvaluator.xcframework',
  ]
end
