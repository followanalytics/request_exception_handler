source 'https://rubygems.org'
# Specify your gem's dependencies in test-unit-context.gemspec
gemspec

gem 'rb-readline'
gem 'pry'
gem 'pry-byebug'
gem 'pry-stack_explorer'

# RAILS_VERSION=3.2.18 bundle update rails
rails_version = ENV['RAILS_VERSION'] || ''
unless rails_version.empty?
  gem 'rails', rails_version
else
  gem 'rails'
end

group :test do
  gem 'nokogiri'
  gem 'minitest'
end
