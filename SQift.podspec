###########################################################################################
#
#  NOTE: This podspec will not pass `pod lib lint` until the following issue is resolved:
#    - https://github.com/CocoaPods/CocoaPods/issues/4607
#
#  However, the podspec does `pod spec lint` successfully.
#
###########################################################################################

Pod::Spec.new do |s|
  s.name = 'SQift'
  s.version = '0.7.0'
  s.license = { :type => 'COMMERCIAL', :text => 'Created and licensed by Nike. Copyright 2015-2016 Nike, Inc. All rights reserved.' }
  s.summary = 'A lightweight Swift wrapper for SQLite.'
  s.homepage = 'http://stash.nikedev.com/projects/NS/repos/sqift/browse'
  s.authors = { 'Dave Camp' => 'dave.camp@nike.com', 'Christian Noon' => 'christian.noon@nike.com' }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.source = { :git => 'ssh://git@stash.nikedev.com/ns/sqift.git', :tag => s.version }
  s.source_files = 'Source/*.{swift,h}'

  s.preserve_paths = 'Modulemaps/**/*'

  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]'  => '$(SRCROOT)/SQift/Modulemaps/iphonesimulator',
    'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]'         => '$(SRCROOT)/SQift/Modulemaps/iphoneos',    
    'SWIFT_INCLUDE_PATHS[sdk=macosx*]'           => '$(SRCROOT)/SQift/Modulemaps/macosx',
    'SWIFT_INCLUDE_PATHS[sdk=appletvsimulator*]' => '$(SRCROOT)/SQift/Modulemaps/appletvsimulator',
    'SWIFT_INCLUDE_PATHS[sdk=appletvos*]'        => '$(SRCROOT)/SQift/Modulemaps/appletvos',
    'SWIFT_INCLUDE_PATHS[sdk=watchsimulator*]'   => '$(SRCROOT)/SQift/Modulemaps/watchsimulator',
    'SWIFT_INCLUDE_PATHS[sdk=watchos*]'          => '$(SRCROOT)/SQift/Modulemaps/watchos'
  }
end
