require File.expand_path('test_helper', File.dirname(__FILE__))

class TestController < ActionController::Base

  def parse; head :ok end

  def parse_with_check_request_exception_skipped; head :ok end

  skip_before_action :check_request_exception, :only =>
    [ :parse_with_check_request_exception_skipped, :parse_with_check_request_exception_replaced ]

  def parse_with_check_request_exception_replaced; head :ok end

  before_action :return_501_on_request_exception, :only => [ :parse_with_check_request_exception_replaced ]

  def return_501_on_request_exception
    head 501 if request_exception
  end

end

class TestWithRexmlRescueController < ActionController::Base

  rescue_from 'REXML::ParseException' do |exception|
    render :text => exception.class.name, :status => 405
  end

  def index; head :ok end

end

class TestWithNokogiriRescueController < ActionController::Base

  rescue_from 'Nokogiri::XML::SyntaxError' do |exception|
    render :text => exception.class.name, :status => 505
  end

  def index; head :ok end

end

RequestExceptionHandlerTest::Application.routes.draw do
  post "/parse_with_rexml_rescue_block", :to => 'test_with_rexml_rescue#index'
  post "/parse_with_nokogiri_rescue_block", :to => 'test_with_nokogiri_rescue#index'
  post '/parse' => "test#parse"
  post '/parse_with_check_request_exception_skipped', :to => "test#parse_with_check_request_exception_skipped"
  post '/parse_with_check_request_exception_replaced', :to => "test#parse_with_check_request_exception_replaced"
end

class RequestExceptionHandlerJsonTest < IntegrationTest

  def test_parse_valid_json
    process :post, '/parse', headers: {'CONTENT_TYPE' => 'application/json'}, params: '{"cicinbrus": {"name": "Ferko"}}'
    assert_response 200
  end

  def test_parse_invalid_json_returns_500_by_default
    process :post, '/parse', headers: {'CONTENT_TYPE' => 'application/json'}, params: '{"cicinbrus": {"name": "Ferko"}'
    assert_response 500
  end

  def test_request_exception_returns_parse_exception_on_invalid_json_request
    process :post, '/parse', headers: {'CONTENT_TYPE' => 'application/json'}, params: "{\"cicinbrus\": {\"name: \"Ferko\"}}"
    assert_not_nil controller.request_exception
    assert_json_parse_exception controller.request_exception
  end

  private

  def assert_json_parse_exception(error)
    if ActiveSupport::JSON.respond_to?(:parse_error) # 2.3.5
      parse_error_class = ActiveSupport::JSON.parse_error
      assert_instance_of parse_error_class, error
    else
      assert_instance_of ActiveSupport::JSON::ParseError, error
    end
  end

end

 # class RequestExceptionHandlerXmlTest < IntegrationTest
 # 
 #   def test_parse_valid_xml
 #     process :post, '/parse', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</name> </cicinbrus>"
 #     assert_response 200
 #   end
 # 
 #   def test_parse_invalid_xml_returns_500_by_default
 #     process :post, '/parse', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko<name> </cicinbrus>"
 #     assert_response 500
 #   end
 # 
 #   def test_controller_responds_to_request_exception_and_returns_nil_on_valid_request
 #     post "/parse"
 #     assert controller.respond_to? :request_exception
 #     assert_nil controller.request_exception
 #   end
 # 
 #   def test_controller_returns_nil_on_request_exception_with_check_request_exception_skipped
 #     post "/parse_with_check_request_exception_skipped"
 #     assert_nil controller.request_exception
 #   end
 # 
 #   def test_request_exception_returns_parse_exception_on_invalid_xml_request
 #     process :post, '/parse', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</namee> </cicinbrus>"
 #     assert_not_nil controller.request_exception
 #     assert_xml_parse_exception controller.request_exception
 #   end
 # 
 #   def test_request_exception_gets_cleared_for_another_valid_request
 #     process :post, '/parse', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</name> </cicinbrus"
 #     process :post, '/parse', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</name> </cicinbrus>"
 #     assert_nil controller.request_exception
 #   end
 # 
 #   def test_request_exception_gets_cleared_for_another_valid_request_with_check_request_exception_skipped
 #     process :post, '/parse_with_check_request_exception_skipped', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</name> </cicinbrus"
 #     process :post, '/parse_with_check_request_exception_skipped', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</name> </cicinbrus>"
 #     assert_nil controller.request_exception
 #   end
 # 
 #   def test_parse_with_check_request_exception_skipped_does_not_reraise_parse_exception
 #     process :post, '/parse_with_check_request_exception_skipped', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</name> </cicinbrus"
 # 
 #     assert_not_nil controller.request_exception
 #     assert_response 200
 #   end
 # 
 #   def test_parse_with_check_request_exception_replaced_does_return_501_on_parse_exception
 #     process :post, '/parse_with_check_request_exception_skipped', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</name> <cicinbrus>"
 #     assert_response 501
 #   end
 # 
 #   def test_on_parse_error_custom_rescue_handler_gets_called
 #     process :post, '/parse_with_rexml_rescue_block', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</name>"
 #     assert_response 405
 #   end
 # 
 #   begin
 #     require 'nokogiri'
 #     NOKOGIRI = true
 #   rescue LoadError
 #     NOKOGIRI = false
 #   end
 # 
 #   def test_on_parse_error_custom_rescue_handler_gets_called_for_nokogiri
 #     return skip('nokogiri not available - test skipped !') unless NOKOGIRI
 # 
 #     backend = ActiveSupport::XmlMini.backend
 #     begin
 #       ActiveSupport::XmlMini.backend = 'Nokogiri'
 #       process :post, '/parse_with_nokogiri_rescue_block', headers: {'CONTENT_TYPE' => 'application/xml'}, params: "<cicinbrus> <name>Ferko</name>"
 #       assert_response 505
 #     ensure
 #       ActiveSupport::XmlMini.backend = backend
 #     end
 #   end if Rails.version >= '4.0'
 # 
 #   private
 # 
 #   def skip(message = nil)
 #     super
 #   end
 # 
 #   def assert_xml_parse_exception(error)
 #     assert_instance_of REXML::ParseException, error
 #   end
 # 
 # end
