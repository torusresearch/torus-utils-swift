Pod::Spec.new do |spec|
  spec.name         = "Torus-utils"
  spec.version      = "0.0.14"
  spec.platform = :ios, "10.0"
  spec.summary      = "Retrieve user shares"
  spec.homepage     = "https://github.com/torusresearch/torus-utils-swift"
  spec.license      = "BSD 3.0"
  spec.swift_version   = "5.0"
  spec.author       = { "Torus Labs" => "rathishubham017@gmail.com" }
  spec.source       = { :git => "https://github.com/torusresearch/torus-utils-swift.git", :tag => "0.0.14" }
  spec.source_files = "Sources/TorusUtils/*.{swift,json}","Sources/TorusUtils/**/*.{swift,json}"
  spec.dependency 'Torus-fetchNodeDetails', '~> 0.0.10'
  spec.dependency 'PromiseKit/Foundation', '~> 6.0'
end
