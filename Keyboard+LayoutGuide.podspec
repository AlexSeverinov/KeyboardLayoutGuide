Pod::Spec.new do |s|
  s.name             = 'Keyboard+LayoutGuide'
  s.version          = "1.6.1"
  s.summary          = "Apple's missing KeyboardLayoutGuide"
  s.homepage         = "https://github.com/AlexSeverinov/KeyboardLayoutGuide"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = 'freshOS'
  s.source           = { :git => "https://github.com/AlexSeverinov/KeyboardLayoutGuide.git",
                         :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/sachadso'
  s.source_files     = "KeyboardLayoutGuide/KeyboardLayoutGuide/*.swift"
  s.requires_arc     = true
  s.ios.deployment_target = "9"
  s.description  = "An alternative approach to handling keyboard in iOS with Autolayout"
  s.module_name = 'KeyboardLayoutGuide'
  s.swift_versions = ['4.2', '5.0', '5.1']
end
