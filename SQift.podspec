Pod::Spec.new do |s|
  s.name = 'SQift'
  s.version = '2.1.0'
  s.license = { :type => 'COMMERCIAL', :text => 'Created and licensed by Nike. Copyright 2015-2017 Nike, Inc. All rights reserved.' }
  s.summary = 'A lightweight Swift wrapper for SQLite.'
  s.homepage = 'https://bitbucket.nike.com/projects/NS/repos/sqift/browse'
  s.authors = { 'Dave Camp' => 'dave.camp@nike.com', 'Christian Noon' => 'christian.noon@nike.com' }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.source = { :git => 'ssh://git@stash.nikedev.com/ns/sqift.git', :tag => s.version }

  s.source_files = [
    'Source/*.swift',
    'Source/sqlite3.h',
  ]

  s.libraries = 'sqlite3'
end
