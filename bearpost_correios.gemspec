$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "bearpost_correios/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "bearpost_correios"
  spec.version     = BearpostCorreios::VERSION
  spec.authors     = ["Lucas Kuhn"]
  spec.email       = ["lucas@nordweg.com"]
  spec.homepage    = ""
  spec.summary     = "Summary of BearpostCorreios."
  spec.description = "Description of BearpostCorreios."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 5.1"

  # spec.add_development_dependency "pg"

  spec.add_development_dependency "listen"
  spec.add_development_dependency 'pg', '>= 0.18', '< 2.0'
  spec.add_development_dependency 'puma', '~> 3.7'
  spec.add_development_dependency 'sass-rails', '~> 5.0'
  spec.add_development_dependency 'uglifier', '>= 1.3.0'
  spec.add_development_dependency 'coffee-rails', '~> 4.2'
  spec.add_development_dependency 'turbolinks', '~> 5'
  spec.add_development_dependency 'jbuilder', '~> 2.5'
end
