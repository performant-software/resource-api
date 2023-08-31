$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "resource_api/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "resource_api"
  spec.version     = ResourceApi::VERSION
  spec.authors     = ["Performant Software"]
  spec.email       = ["derek@performantsoftware.com"]
  spec.homepage    = "https://github.com/performant-software/resource-api"
  spec.summary     = "A simple API framework for RESTFUL CRUD operations"
  spec.description = "A set of classes to use as a framework for controllers, models, and serializers for building an API."
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

  spec.add_dependency "rails", ">= 7.0", "< 8"
  spec.add_dependency "pagy", "~> 5.10"
  spec.add_dependency "pundit", "~> 2.3.1"

  spec.add_development_dependency "sqlite3"
end
