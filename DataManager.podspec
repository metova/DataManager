Pod::Spec.new do |s|

  s.name         = "DataManager"
  s.version      = "2.1.0"
  s.summary      = "DataManager is a small utility class that helps you manage Core Data."
  s.description  = <<-DESC
DataManager takes care of Core Data boilerplate code for you. It handles setting up the Core Data stack with support for asynchronous saves. It also includes a few simple fetch and deletion methods.
                   DESC
  s.homepage     = "https://github.com/metova/DataManager"
  s.license      = "MIT"
  s.author       = { "Logan Gauthier" => "logan.gauthier@metova.com" }

  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.13"
  s.watchos.deployment_target = "10.0"
  s.tvos.deployment_target = "17.0"

  s.platform = :ios, '12.0'
  s.swift_version = '5.0'

  s.source       = { :git => "https://github.com/metova/DataManager.git", :tag => s.version.to_s }
  s.source_files  = "Sources/*.swift"

  s.framework  = "CoreData"

end
