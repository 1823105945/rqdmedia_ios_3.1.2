source 'https://github.com/CocoaPods/Specs.git'
install! 'cocoapods', :deterministic_uuids => false
inhibit_all_warnings!

def shared_pods
  pod 'XKKeychain', '~>1.0'
  pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has a logout function added
  pod 'upnpx', '~>1.4.0'
  pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
  pod 'VLC-WhiteRaccoon'
  pod 'VLC-LiveSDK', '5.7.0x'
  pod 'ObjectiveDropboxOfficial', :git => 'git://github.com/carolanitz/dropbox-sdk-obj-c.git' #update ios platform version
end

def iOS_pods
  pod 'OBSlider', '1.1.0'
  pod 'InAppSettingsKit', :git => 'git://github.com/fkuehne/InAppSettingsKit.git', :commit => '415ea6bb' #tvOS fix
  pod 'HockeySDK', '~>5.1.2', :subspecs => ['CrashOnlyLib']
  pod 'RESideMenu', '~>4.0.7'
  pod 'PAPasscode', '~>1.0'
  pod 'GoogleAPIClient/Drive'
  pod 'VLC-LXReorderableCollectionViewFlowLayout', '0.1.3v'
  pod 'MediaLibraryKit-prod'
  pod 'MobileVLCKit', '3.1.4'
  pod 'GTMAppAuth'
  pod 'SDWebImage'
  pod 'NoticeView'
  pod 'UIActionSheet+Blocks'
  pod 'SDSegmentedControl'
  pod 'WTStatusBar'
  pod 'PDKeychainBindingsController'
  pod 'FontAwesomeIconFactory'
  pod 'Masonry'
  pod 'UMCCommon'
  pod 'UMCAnalytics'
  pod 'UMCSecurityPlugins'
  pod 'UMCCommonLog'
#  pod 'Crashlytics'
end

target 'rqdMedia-iOS' do
  platform :ios, '9.0'
  shared_pods
  iOS_pods
end

target 'rqdMedia-iOS-no-watch' do
  platform :ios, '9.0'
  shared_pods
  iOS_pods
end

target 'rqdMedia-tvOS' do
  platform :tvos, '10.2'
  shared_pods
  pod 'MetaDataFetcherKit', '~>0.3.1'
  pod "OROpenSubtitleDownloader", :git => 'https://github.com/orta/OROpenSubtitleDownloader.git', :commit => '0509eac2'
  pod 'GRKArrayDiff', '~> 2.1'
  pod 'HockeySDK-tvOS', '~>5.0.0'
  pod 'TVVLCKit', '3.1.4'
end

target 'rqdMedia-watchOS-Extension' do
  platform :watchos, '2.0'
  pod 'MediaLibraryKit-unstable'
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    if target.name == 'rqdMedia-watchOS-Extension'
      installer_representation.pods_project.build_configurations.each do |config|
        config.build_settings['SKIP_INSTALL'] = 'YES'
        config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
        config.build_settings['VALID_ARCHS'] = 'armv7 armv7s arm64 i386 armv7k'
        config.build_settings['ARCHS'] = 'armv7 armv7s arm64 i386 armv7k'
      end
    else
      installer_representation.pods_project.build_configurations.each do |config|
        config.build_settings['SKIP_INSTALL'] = 'YES'
        config.build_settings['VALID_ARCHS'] = 'armv7 armv7s arm64 i386 armv7k'
        config.build_settings['ARCHS'] = 'armv7 armv7s arm64 i386 armv7k'
        config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
      end
    end
  end
end
