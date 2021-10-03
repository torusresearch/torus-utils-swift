Pod::Spec.new do |spec|
  spec.name         = "Torus-utils"
  spec.version      = "1.1.1"
  spec.platform = :ios, "11.0"
  spec.summary      = "Retrieve user shares"
  spec.homepage     = "https://github.com/torusresearch/torus-utils-swift"
  spec.license      = { :type => 'BSD', :file => 'License.md' }
  spec.swift_version   = "5.0"
  spec.author       = { "Torus Labs" => "rathishubham017@gmail.com" }
  spec.module_name = "TorusUtils"
  spec.source       = { :git => "https://github.com/torusresearch/torus-utils-swift.git", :tag => spec.version }
  spec.source_files = "Sources/TorusUtils/*.{swift,json}","Sources/TorusUtils/**/*.{swift,json}"
  spec.dependency 'Torus-fetchNodeDetails', '~> 1.1.0'
  spec.dependency 'CryptoSwift', '~> 1.4.1'
  spec.dependency 'secp256k1.swift', '~> 0.1.4'
  spec.dependency 'PromiseKit/Foundation', '~> 6.0'
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
