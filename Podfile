platform :ios, '12.0'

abstract_target 'DataManager' do

  pod 'SwiftLint'

  target 'DataManager iOS' do
    target 'DataManager iOS Tests' do
      inherit! :search_paths
    end
  end

  target 'DataManager OSX' do
    target 'DataManager OSX Tests' do
      inherit! :search_paths
    end
  end

  target 'DataManager tvOS' do
    target 'DataManager tvOS Tests' do
      inherit! :search_paths
    end
  end

  target 'DataManager watchOS' do
  end
end

post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
            end
        end
    end
end
