Pod::Spec.new do |spec|
  spec.name         = "Torus-utils"
  spec.version      = "5.1.0"
  spec.ios.deployment_target  = "13.0"
  spec.summary      = "Retrieve user shares"
  spec.homepage     = "https://github.com/torusresearch/torus-utils-swift"
  spec.license      = { :type => 'BSD', :file => 'License.md' }
  spec.swift_version   = "5.0"
  spec.author       = { "Torus Labs" => "rathishubham017@gmail.com" }
  spec.module_name = "TorusUtils"
  spec.source       = { :git => "https://github.com/torusresearch/torus-utils-swift.git", :tag => spec.version }
  spec.source_files = "Sources/TorusUtils/*.{swift,json}","Sources/TorusUtils/**/*.{swift,json}"
  spec.dependency 'Torus-fetchNodeDetails', '~> 4.0.1'
  spec.dependency 'CryptoSwift', '~> 1.7.1'
  spec.dependency 'secp256k1.swift', '~> 0.1.4'
end
