Pod::Spec.new do |s|
  s.name             = "Umarell"
  s.version          = "1.0.4"
  s.summary          = "Umarell is a easy-to-use library that makes simple the implementation of the Publish-Subscribe pattern in Objective-C."
  s.homepage         = "https://github.com/sysdatadigital/Umarell"
  s.license          = 'Apache 2.0'
  s.author           = { "Sysdata Digital" => "team.mobile@sysdata.it" }
  s.source           = { :git => "https://github.com/sysdatadigital/Umarell.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Umarell'
end