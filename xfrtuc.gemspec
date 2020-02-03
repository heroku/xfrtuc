require File.expand_path('../lib/xfrtuc/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Maciek Sakrejda"]
  gem.email         = ["m.sakrejda@gmail.com"]
  gem.description   = %q{Transferatu client}
  gem.summary       = %q{Transferatu client: see https://github.com/heroku/transferatu}
  gem.homepage      = "https://github.com/heroku/xfrtuc"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "xfrtuc"
  gem.require_paths = ["lib"]
  gem.version       = Xfrtuc::VERSION
  gem.license       = "MIT"

  gem.add_runtime_dependency 'rest-client', '~> 2.0'

  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'sham_rack', '~> 1.3'
end
