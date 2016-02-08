Gem::Specification.new do |s|
  s.name	    	= 'hive-runner-android'
  s.version	    	= '1.1.3'
  s.date 	    	= '2015-02-26'
  s.summary	    	= 'Hive Runner Android'
  s.description		= 'The Android controller module for Hive Runner'
  s.authors	    	= ['Jon Wilson']
  s.email	      	= 'jon.wilson01@bbc.co.uk'
  s.files 	    	= Dir['README.md', 'lib/**/*.rb']
  s.homepage  		= 'https://github.com/bbc/hive-runner-android'
  s.license	    	= 'MIT'
  s.add_runtime_dependency 'device_api-android', '~> 1.0'
  s.add_runtime_dependency 'hive-runner', '~> 2.0.5'
  s.add_runtime_dependency 'terminal-table', '>= 1.4'
end
