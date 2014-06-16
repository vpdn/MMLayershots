Pod::Spec.new do |s|
  s.name          = "MMLayershots"
  s.version       = "0.2.5"
  s.summary       = "Generates a Photoshop (PSD) file from your app view hierachy."
  s.homepage      = "https://github.com/vpdn/MMLayershots/"
  s.license       = 'MIT'
  s.author        = { "vpdn" => "vp@dinhmail.de" }
  s.source        = { :git => "https://github.com/vpdn/MMLayershots.git", :tag => s.version.to_s, :submodules => true }
  s.platform      = :ios, '7.0'
  s.source_files  = 'MMLayershots/*.{h,m}', 'MMLayershots/SFPSDWriter/Library/**/*.{h,m}'
  s.requires_arc  = true
end