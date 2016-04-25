#
#  Be sure to run `pod spec lint DataManager.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "DataManager"
  s.version      = "0.1.0"
  s.summary      = "DataManager is a small utility class that helps you manage Core Data."
  s.description  = <<-DESC
DataManager takes care of Core Data boilerplate code for you. It handles setting up the Core Data stack with support for asynchronous saves. It also includes a few simple fetch and deletion methods.
                   DESC
  s.homepage     = "https://github.com/metova/DataManager"
  s.license      = "MIT"
  s.author       = { "Logan Gauthier" => "logan.gauthier@metova.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "http://github.com/metova/DataManager.git", :tag => "0.1.0" }
  s.source_files  = "Source/*.swift"

  s.framework  = "CoreData"

end
