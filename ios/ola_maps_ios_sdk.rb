# frozen_string_literal: true

# Installs OlaMapCore with every xcframework the binary actually links
# (MoEngageCards, MoEngageInApps, MoEngageTriggerEvaluator, …).
#
# Needed only when Swift Package Manager is disabled. With Flutter 3.44+,
# `ios/ola_maps/Package.swift` embeds these frameworks automatically.
#
# In your app Podfile, after `flutter_install_all_ios_pods`:
#
#   require File.join(File.dirname(File.realpath(__FILE__)),
#                     '.symlinks/plugins/ola_maps/ios/ola_maps_ios_sdk.rb')
#   install_ola_maps_ios_sdk!
#
def install_ola_maps_ios_sdk!
  podspec = File.expand_path('OlaMapCore.podspec', __dir__)
  pod 'OlaMapCore', :podspec => podspec
end
