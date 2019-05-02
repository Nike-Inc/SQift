Pod::Spec.new do |s|
  s.name = "SQift"
  s.version = "4.1.1"
  s.license = "MIT"
  s.summary = "A lightweight Swift wrapper for SQLite."
  s.homepage = "https://github.com/Nike-Inc/SQift"
  s.authors = { "Dave Camp" => "dave.camp@nike.com", "Christian Noon" => "christian.noon@nike.com" }

  s.source = { :git => "https://github.com/Nike-Inc/SQift.git", :tag => s.version }
  s.source_files = "Source/**/*.swift"
  s.swift_versions = ["4.2", "5.0"]

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.12"
  s.tvos.deployment_target = "10.0"
  s.watchos.deployment_target = "3.0"

  s.libraries = "sqlite3"
end
