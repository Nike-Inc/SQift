Pod::Spec.new do |s|
  s.name = "SQift"
  s.version = "3.2.1"
  s.license = "MIT"
  s.summary = "A lightweight Swift wrapper for SQLite."
  s.homepage = "https://github.com/Nike-Inc/SQift"
  s.authors = { "Dave Camp" => "dave.camp@nike.com", "Christian Noon" => "christian.noon@nike.com" }

  s.source = { :git => "https://github.com/Nike-Inc/SQift.git", :tag => s.version }
  s.source_files = "Source/**/*.swift"
  s.swift_version = "4.2"

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"

  s.libraries = "sqlite3"
end
