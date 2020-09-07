#
# Be sure to run `pod lib lint ERMarkup.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ERMarkup'
  s.version          = '0.1.15'
  s.summary          = 'A wrapper markup base on Drawsana with nicer UI'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!


  s.homepage         = 'https://github.com/trungnguyen1791/ERMarkup'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'trungnguyen1791' => 'trungnguyen.1791@gmail.com' }
  s.source           = { :git => 'https://github.com/trungnguyen1791/ERMarkup.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'ERMarkup/Classes/**/*.swift'
  
  s.resource_bundles = {
     'ERMarkup' => ['ERMarkup/Assets/*.png']
  }
  s.resources    = ['ERMarkup/**/*.{png}']

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Drawsana', '~> 0.9.2'
  #s.dependency 'LiquidButton'
  s.dependency 'FTPopOverMenu_Swift', '~> 0.2.0'
  
  s.swift_version = '4.2'
  s.platform     = :ios, '10.0'

end
