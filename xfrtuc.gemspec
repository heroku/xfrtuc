# frozen_string_literal: true

require File.expand_path("../lib/xfrtuc/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors = ["Maciek Sakrejda"]
  gem.email = ["m.sakrejda@gmail.com"]
  gem.description = "Transferatu client"
  gem.summary = "Transferatu client: see https://github.com/heroku/transferatu"
  gem.homepage = "https://github.com/heroku/xfrtuc"

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.name = "xfrtuc"
  gem.require_paths = ["lib"]
  gem.version = Xfrtuc::VERSION
  gem.license = "MIT"
end
