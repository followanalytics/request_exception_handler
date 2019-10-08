require 'rubygems'
require 'bundler/setup' rescue nil
require 'pry'
require 'pry-byebug'
require 'pry-stack_explorer'
require 'nokogiri'

# enable testing with different version of rails via argv :
# ruby request_exception_handler_test.rb RAILS_VERSION=2.3.18
version =
  if ARGV.find { |opt| /RAILS_VERSION=([\d\.]+)/ =~ opt }
    $~[1]
  else
    ENV['RAILS_VERSION'] # rake test RAILS_VERSION=3.2.18
  end

if version
  RAILS_VERSION = version
  gem 'activesupport', "#{RAILS_VERSION}"
  gem 'actionpack', "#{RAILS_VERSION}"
  gem 'rails', "#{RAILS_VERSION}"
else
  gem 'activesupport'
  gem 'actionpack'
  gem 'rails'
end unless defined? Bundler

require 'rails/version'
puts "emulating Rails.version = #{Rails::VERSION::STRING}"

require 'active_support'
require 'active_support/test_case'
require 'action_controller'
require 'action_controller/test_case'
require 'action_dispatch'
require 'action_dispatch/routing'

require 'action_dispatch/testing/integration'
IntegrationTest = ActionDispatch::IntegrationTest

ActiveSupport::Deprecation.behavior = :stderr

require 'rails'
# a minimal require 'rails/all' :
require 'action_controller/railtie'
require 'rails/test_help'

silence_warnings { RAILS_ROOT = File.expand_path( File.dirname(__FILE__) ) }

# Make double-sure the RAILS_ENV is set to test,
# so fixtures are loaded to the right database
silence_warnings { RAILS_ENV = 'test' }

Rails.backtrace_cleaner.remove_silencers! if Rails.backtrace_cleaner

module Rails # make sure we can set the logger
  class << self
    attr_accessor :logger
  end
end

File.open(File.join(File.dirname(__FILE__), 'test.log'), 'w') do |file|
  Rails.logger = Logger.new(file.path)
end

module RequestExceptionHandlerTest

  class Application < Rails::Application; end

  Application.configure do
    if config.respond_to?(:secret_key_base=)
      config.secret_key_base = 'x' * 30
    else
      config.secret_token = 'x' * 30
    end
    config.cache_classes = true if config.respond_to?(:cache_classes=)
    config.eager_load = false if config.respond_to?(:eager_load=)
    config.action_controller.allow_forgery_protection = false
    config.active_support.deprecation = :stderr
  end

  unless ActionDispatch::ParamsParser::DEFAULT_PARSERS[ Mime::XML ]
    ActionDispatch::ParamsParser::DEFAULT_PARSERS[ Mime::XML ] = Proc.new do
      |raw_post| ( Hash.from_xml(raw_post) || {} ).with_indifferent_access
    end
  end if defined? ActionDispatch::ParamsParser::DEFAULT_PARSERS

  Application.initialize!

end

$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'request_exception_handler'
