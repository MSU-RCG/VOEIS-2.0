source :rubygems

gem "yogo-framework", :path =>  "../yogo-framework"

gem "data_mapper"
gem "dm-is-list"
gem "dm-is-versioned"
gem "jquery-rails"

# Extra supporting gems
gem "rails"
gem "dm-rails"
gem "inherited_resources"
gem "carrierwave"
gem "compass", ">= 0.10.6"
gem "bcrypt-ruby"
gem "haml"
gem "mime-types",                   :require => "mime/types"
gem "uuidtools"
gem 'rails_warden'
gem "json",                         :require => nil
gem 'pony'
gem 'polyglot'
gem 'treetop'
gem 'mail'

platforms(:ruby_18) { gem "fastercsv" }

group(:development, :test) do
  gem "capistrano",                :require => nil
  gem "bluecloth",                 :require => nil # Required for YARD
  gem "rake",                      :require => nil
  gem 'rspec'
  gem 'rspec-core',                :require => 'rspec/core'
  gem 'rspec-expectations',        :require => 'rspec/expectations'
  gem 'rspec-mocks',               :require => 'rspec/mocks'
  gem 'rspec-rails'
  gem "yard",                      :require => nil
  gem "yardstick",                 :require => nil
  gem "jeweler",                   :require => nil
end
