require "test/unit"
require_relative "../lib/config"
require_relative "../lib/client"

class TestClient < Test::Unit::TestCase
  # Can we connect?
  def setup
    @creds  = R53z::Config.new()
    @client = R53z::Client.new('default', @creds)
  end

  def test_read
    assert_instance_of(R53z::Client, @client)
    zones = @client.list
    assert(zones.to_s.include?('alertcat.com'))
    records = @client.record_list(zones.first[:id])
    assert(records.to_s.include?('resource_records'))
  end
end

