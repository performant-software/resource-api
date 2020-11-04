# Resource API
The Resource API gem is a framework for building a simple RESTFUL API in a Rails application. It provides bases classes that can be extended to customize the functionality to fit your needs.

## Build
```
gem build resource-api.gemspec
```

## Installation
Update your SSH config to use your SSH key to access the resource-api repository:

```
# ~/.ssh/config

Host resource-api
  HostName github.com
  IdentityFile ~/.ssh/id_rsa
```

Add this line to your application's Gemfile:

```ruby
gem 'resource_api', git: 'git@resource-api:performant-software/resource-api.git'
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

### Heroku
When deploying to a staging server on Heroku, we'll need to allow Heroku access to the resource-api repository in order to install dependencies. This section will describe how to do that.

#### Copy preinstall and postinstall scripts
Copy the `preinstall.sh` and `postinstall.sh` scripts from this repository into your project. It doesn't matter where, but a directory named `scripts` is usually a good idea.

Modifications to the scripts may be necessary if using more than one private repo.

#### Update package.json
In your root level `package.json`, add or append the following to the `scripts` object:
```
"heroku-prebuild": "bash ./scripts/preinstall.sh"
"heroku-postbuild": "bash ./scripts/postinstall.sh"
```
These two scripts will install your SSH key prebuild, then after the dependencies are installed, remove it.

Note: The heroku-prebuild and heroku-postbuild scripts require the NodeJS buildpack. 

You'll want to use the following syntax for defining the `resource_api` dependency in your Gemfile:

```ruby
gem 'resource_api', git: 'git@resource-api:performant-software/resource-api.git'
```

Note: `yarn` does not seem to work with the above syntax. It is recommended to use `npm`.

#### Generate a deploy key
From your computer, generate a new public/private SSH key pair using the following command and save the key pair somewhere secure.
```
ssh-keygen -t rsa
```

Copy the public key using:
```
pbcopy < my-awesome-project-staging-deploy-key.pub
```

Within the resource-api repository on GitHub, go to Settings > Deploy Keys. Add the copied public key for your project. Name it something obvious like "My Awesome Project Staging" so that others will know what it is used for.

#### Add your deploy key to Heroku
Convert the private key from PEM to base64 using the following command and copy the value.
```
cat my-awesome-project-staging-deploy-key | base64
```

In the Heroku dashboard for your app, navigate to the Settings tab. Add a config var with key `RESOURCE_API_SSH_KEY` and paste the value copied from the private deploy key.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
