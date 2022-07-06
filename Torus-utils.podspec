Pod::Spec.new do |spec|
  spec.name         = "Torus-utils"
  spec.version      = "3.0.0"
  spec.platform = :ios, "13.0"
  spec.summary      = "Retrieve user shares"
  spec.homepage     = "https://github.com/torusresearch/torus-utils-swift"
  spec.license      = { :type => 'BSD', :file => 'License.md' }
  spec.swift_version   = "5.0"
  spec.author       = { "Torus Labs" => "rathishubham017@gmail.com" }
  spec.module_name = "TorusUtils"
  spec.source       = { :git => "https://github.com/torusresearch/torus-utils-swift.git", :tag => spec.version }
  spec.source_files = "Sources/TorusUtils/*.{swift,json}","Sources/TorusUtils/**/*.{swift,json}"
  spec.dependency 'Torus-fetchNodeDetails', '~> 3.0.0'
  spec.dependency 'CryptoSwift', '~> 1.5.1'
  spec.dependency 'secp256k1.swift', '~> 0.1.4'
  spec.dependency 'PromiseKit/Foundation', '~> 6.0'
  spec.dependency 'TweetNacl'
end
