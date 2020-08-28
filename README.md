# Resource API
The Resource API gem is a framework for building a simple RESTFUL API in a Rails application. It provides bases classes that can be extended to customize the functionality to fit your needs.

## Build
```
gem build resource-api.gemspec
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'resource-api', github: 'https://github.com/performant-software/resource-api'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install resource-api
```

## Usage

#### Controllers
Controllers are setup in a way to perform based CRUD operations without much need for customization. Define your allowed parameters in your models (see below) and the controller will handle the rest. The `Api::ResourceController` also provides protected methods that can be overwritten or extended to customize functionality:
```ruby
def apply_filters(query)
  return query unless params[:homeroom].present?
  
  query.where(homeroom: params[:homeroom])
end
```

The `Api::ResourceController` uses the `Queryable` concern to build your query on the `#index` and `#show` routes. You can use the `preloads`, `joins`, `left_joins`, and `per_page` methods to optimize the query and avoid unnecessary queries during serialization.

```ruby
class Api::StudentsController < Api::ResourceController
  per_page 20
  preloads :school, :classes
end
```

#### Models
Models can be setup using the `Resourceable` concern to define strong parameters. The list of parameters can be acessed using `<ModelName>.permitted_params` (i.e. `Student.permitted_params`). This is done automatically in the `Api::ResourceController` in order to enforce the appropriate parameters.

```ruby
class Student < ApplicationRecord
  include Resourceable

  belongs_to :school
  has_many :classes, dependent: :destroy

  accepts_nested_attributes_for :classes, allow_destroy: true

  allow_params :first_name, :last_name, :yog, :dob, :homeroom,
               classes_attributes: [:id, :section_id, :_destroy]
end
```

#### Serializers
Serializers use the `ObjectSerializer` concern to define which attributes to render and when.

The `index_attributes` and `belongs_to` attributes defined will be rendered on the `#index` route.

The `show_attributes`, `belongs_to`, and `has_many` attributes defined will be rendered on the `#show`, `#create`, and `#update` routes.

```ruby
class StudentsSerializer < BaseSerializer
  index_attributes :id, :first_name, :last_name
  
  show_attributes :id, :first_name, :last_name, :yog, :dob, :homeroom
  
  has_many classes: [:id, :section_id]
  
  belongs_to school: SchoolsSerializer
end
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
