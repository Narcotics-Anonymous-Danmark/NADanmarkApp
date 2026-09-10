Pod::Spec.new do |s|
  s.name             = 'adapter_legacy_store'
  s.version          = '0.1.0'
  s.summary          = 'Reads the Ionic Storage IndexedDB of the previous NA Danmark app.'
  s.description      = <<-DESC
Opens an offscreen WKWebView at the legacy ionic://localhost origin and dumps the _ionicstorage IndexedDB as JSON.
                       DESC
  s.homepage         = 'https://nadanmark.dk'
  s.license          = { :type => 'MIT' }
  s.author           = { 'NA Danmark' => 'app@nadanmark.dk' }
  s.source           = { :path => '.' }
  s.source_files = 'adapter_legacy_store/Sources/adapter_legacy_store/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
