
Pod::Spec.new do |s|

  s.name         = "CrediteaseTracking"
  s.version      = "0.0.1"
  s.summary      = "CrediteaseTracking is used for tracking"

  s.description  = <<-DESC
                    CrediteaseTracking is used for tracking in big data center for all app. I just test for pods
                   DESC

  s.homepage     = "https://github.com/csjlengxiang"
  s.license      = "MIT"


  s.author       = { "Chen Sijie" => "sijiechen3@creditease.cn" }
 
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/csjlengxiang/CrediteaseTrackingDemo.git", :tag => "#{s.version}" }

  s.source_files = "CrediteaseTrackingDemo/CrediteaseTracking/**/*.{h,m}"


  s.dependency "AFNetworking"
  s.dependency "FMDB"

end
