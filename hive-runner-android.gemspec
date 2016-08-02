Gem::Specification.new do |s|
  s.name        = 'hive-runner-android'
  s.version       = '1.2.7.pre'
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary       = 'Hive Runner Android'
  s.description   = 'The Android controller module for Hive Runner'
  s.authors       = ['Jon Wilson','David Craddock']
  s.email         = 'jon.wilson01@bbc.co.uk, david.craddock@bbc.co.uk'
  s.files         = Dir['README.md', 'lib/**/*.rb']
  s.homepage      = 'https://github.com/bbc/hive-runner-android'
  s.license       = 'MIT'
  s.add_runtime_dependency 'device_api-android'
  s.add_runtime_dependency 'hive-runner', '~> 2.1.1'
  s.add_runtime_dependency 'terminal-table', '>= 1.4'
end
