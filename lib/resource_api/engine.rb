Gem.loaded_specs['resource_api'].dependencies.each do |d|
  require d.name unless d.type == :development
end

require 'resource_api/engine'

module ResourceApi
  class Engine < ::Rails::Engine
  end
end
