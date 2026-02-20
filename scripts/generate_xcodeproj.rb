require 'xcodeproj'

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'TelbisesAIDealScout.xcodeproj')
project = Xcodeproj::Project.new(project_path)

app_target = project.new_target(:application, 'TelbisesAIDealScout', :ios, '17.0')
test_target = project.new_target(:unit_test_bundle, 'TelbisesAIDealScoutTests', :ios, '17.0')
test_target.add_dependency(app_target)
test_target.frameworks_build_phase.add_file_reference(app_target.product_reference)

# Groups
sources_group = project.main_group.find_subpath('Sources', true)
app_sources_group = sources_group.find_subpath('TelbisesAIDealScout', true)
tests_group = project.main_group.find_subpath('Tests', true)
app_tests_group = tests_group.find_subpath('TelbisesAIDealScoutTests', true)

# Add app Swift sources
Dir.glob(File.join(root, 'Sources', 'TelbisesAIDealScout', '**', '*.swift')).sort.each do |path|
  rel = Pathname.new(path).relative_path_from(Pathname.new(root)).to_s
  file_ref = app_sources_group.new_file(rel)
  app_target.add_file_references([file_ref])
end

# Add app resources
Dir.glob(File.join(root, 'Sources', 'TelbisesAIDealScout', 'Resources', '*')).sort.each do |path|
  next if File.directory?(path)
  rel = Pathname.new(path).relative_path_from(Pathname.new(root)).to_s
  file_ref = app_sources_group.new_file(rel)
  app_target.resources_build_phase.add_file_reference(file_ref)
end

# Add test Swift sources
Dir.glob(File.join(root, 'Tests', 'TelbisesAIDealScoutTests', '*.swift')).sort.each do |path|
  rel = Pathname.new(path).relative_path_from(Pathname.new(root)).to_s
  file_ref = app_tests_group.new_file(rel)
  test_target.add_file_references([file_ref])
end

app_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.telbises.TelbisesAIDealScout'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UIStatusBarStyle'] = 'UIStatusBarStyleDefault'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
end

test_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.telbises.TelbisesAIDealScoutTests'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/TelbisesAIDealScout.app/TelbisesAIDealScout'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @loader_path/Frameworks'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
end

project.recreate_user_schemes
project.save
puts "Generated #{project_path}"
