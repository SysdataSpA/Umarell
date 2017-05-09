Pod::Spec.new do |s|
  s.name             = "Umarell"
  s.version          = "1.2.0"
  s.summary          = "Umarell is a easy-to-use library that makes simple the implementation of the Publish-Subscribe pattern in Objective-C."
  s.homepage         = "https://github.com/SysdataSpA/Umarell.git"
  s.license          = 'Apache 2.0'
  s.author           = { "Sysdata Digital" => "team.mobile@sysdata.it" }
  s.source           = { :git => "https://github.com/SysdataSpA/Umarell.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.subspec 'Core' do |co|
     co.source_files = 'Umarell'
  end

  s.subspec 'Blabber' do |bl|
     bl.dependency 'Umarell/Core'
     bl.dependency 'Blabber'
     bl.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'BLABBER=1' }
  end

  s.default_subspec = 'Core'
  
end