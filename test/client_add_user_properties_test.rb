require 'helper'

class ClientAddUserPropertiesTest < MiniTest::Test
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @heap = HeapAPI::Client.new
    @heap.app_id = 'test-app-id'
    @heap.faraday_adapter = :test
    @heap.faraday_adapter_args = [@stubs]
  end

  def teardown
    @stubs.verify_stubbed_calls
  end

  def test_add_user_properties_without_app_id
    @heap.app_id = nil
    exception = assert_raises RuntimeError do
      @heap.add_user_properties 'test-handle', 'key' => 'value'
    end
    assert_equal RuntimeError, exception.class
    assert_equal 'Heap app_id not set', exception.message
  end

  def test_add_user_properties_with_long_property_name
    long_name = 'A' * 1025

    exception = assert_raises ArgumentError do
      @heap.add_user_properties 'test-handle', long_name => 'value'
    end
    assert_equal ArgumentError, exception.class
    assert_equal "Property name #{long_name} too long; " +
        '1025 is above the 1024-character limit', exception.message
  end

  def test_add_user_properties_with_long_string_property_value
    long_value = 'A' * 1025
    exception = assert_raises ArgumentError do
      @heap.add_user_properties 'test-handle', 'long_value_name' => long_value
    end
    assert_equal ArgumentError, exception.class
    assert_equal "Property long_value_name value \"#{long_value}\" too " +
        'long; 1025 is above the 1024-character limit', exception.message
  end

  def test_add_user_properties_with_long_symbol_property_value
    long_value = ('A' * 1025).to_sym
    exception = assert_raises ArgumentError do
      @heap.add_user_properties 'test-handle', 'long_value_name' => long_value
    end
    assert_equal ArgumentError, exception.class
    assert_equal "Property long_value_name value :#{long_value} too long; " +
        '1025 is above the 1024-character limit', exception.message
  end

  def test_add_user_properties_with_array_property_value
    exception = assert_raises ArgumentError do
      @heap.add_user_properties 'test-handle', 'array_value_name' => []
    end
    assert_equal ArgumentError, exception.class
    assert_equal 'Unsupported type for property array_value_name value []',
        exception.message
  end


  def test_add_user_properties
    @stubs.post '/api/identify' do |env|
      golden_body = {
        'app_id' => 'test-app-id',
        'identity' => 'test-handle',
        'properties' => { 'foo' => 'bar', 'heap' => 'hurray' }
      }
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal @heap.user_agent, env[:request_headers]['User-Agent']
      assert_equal golden_body, JSON.parse(env[:body])

      [200, { 'Content-Type' => 'text/plain; encoding=utf8' }, '']
    end

    assert_equal @heap, @heap.add_user_properties('test-handle',
        'foo' => 'bar', :heap => :hurray)
  end

  def test_add_user_properties_error
    @stubs.post '/api/identify' do |env|
      [400, { 'Content-Type' => 'text/plain; encoding=utf8' }, 'Bad request']
    end

    exception = assert_raises HeapAPI::Error do
      @heap.add_user_properties 'test-handle', 'foo' => 'bar'
    end

    assert_equal HeapAPI::ApiError, exception.class
    assert_equal 'Heap API server error: 400 Bad request', exception.message
    assert_kind_of Faraday::Response, exception.response
    assert_equal 400, exception.response.status
  end

  def test_add_user_properties_integration
    @heap.app_id = '3000610572'
    @heap.faraday_adapter = :net_http
    @heap.faraday_adapter_args = []

    assert_equal @heap, @heap.add_user_properties('test-handle',
        'language/ruby' => 1, 'heap/heap-ruby' => 1)
  end

  def test_add_user_properties_error_integration
    @heap.faraday_adapter = :net_http
    @heap.faraday_adapter_args = []

    assert_raises HeapAPI::Error do
      @heap.add_user_properties 'test-handle',
          'language/ruby' => 1, 'heap/heap-ruby' => 1
    end
  end

  def test_add_user_properties_with_stubbed_connection
    @heap.stubbed = true

    assert_equal @heap, @heap.add_user_properties('test-handle',
        'foo' => 'bar', :heap => :hurray)
  end
end
