# Podfile for AFHAM iOS
# BrainSAIT Healthcare AI Platform

platform :ios, '17.0'
use_frameworks!
inhibit_all_warnings!

# Define workspace
workspace 'AFHAM.xcworkspace'

target 'AFHAM' do
  # Networking
  pod 'Alamofire', '~> 5.9'

  # JSON Parsing
  pod 'SwiftyJSON', '~> 5.0'

  # Image Loading & Caching
  pod 'Kingfisher', '~> 7.11'

  # Keychain Wrapper
  pod 'KeychainAccess', '~> 4.2'

  # Analytics (Privacy-focused)
  pod 'FirebaseAnalytics', '~> 10.20'
  pod 'FirebaseCrashlytics', '~> 10.20'

  # FHIR Support
  pod 'SMART', '~> 4.2'

  # Encryption
  pod 'CryptoSwift', '~> 1.8'

  # Local Database
  pod 'RealmSwift', '~> 10.47'

  # Testing (for development)
  target 'AFHAMTests' do
    inherit! :search_paths
    pod 'Quick', '~> 7.4'
    pod 'Nimble', '~> 13.2'
  end

  target 'AFHAMUITests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'

      # Security hardening
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'COCOAPODS=1'

      # Optimize for size and speed
      config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = 's'
    end
  end
end
