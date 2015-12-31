Pod::Spec.new do |s|
  s.name = 'SQift'
  s.version = '0.3.0'
  s.license = { :type => 'COMMERCIAL', :text => 'Created and licensed by Nike. Copyright 2015 Nike, Inc. All rights reserved.' }
  s.summary = 'A lightweight Swift wrapper for SQLite.'
  s.homepage = 'http://stash.nikedev.com/projects/NS/repos/sqift/browse'
  s.authors = { 'Dave Camp' => 'dave.camp@nike.com', 'Christian Noon' => 'christian.noon@nike.com' }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.source = { :git => 'ssh://git@stash.nikedev.com/ns/sqift.git', :tag => s.version }
  s.source_files = 'Source/*.{swift,h}'

  s.dependency 'SQLCipher', '~> 3.3'

  s.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SQLITE_HAS_CODEC=1' }
end
