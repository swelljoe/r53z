require "test/unit"
require_relative "../lib/r53z"

class TestFile < Test::Unit::TestCase
  def setup
    @zone = { :name => "000000test.com", :type => "SOA", :region => "us-east-1", :ttl => "1", :resource_records => [{ :value => "ns-895.awsdns-47.net. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"}]} 
    # test_file
    @filename = 'test/tmp/000000test.com.json'
    R53z::JsonFile.write_json(path: @filename, data: @zone)
  end

  def teardown
    # make sure tmp file is deleted
    if File.file?(@filename)
      File.delete(@filename)
    end
  end

  def test_write
    # Can we write a new zone file?
    R53z::JsonFile.write_json(path: @filename, data: @zone)
    assert(File.file?(@filename))
  end

  def test_read
    # Can we read it back in?
    zone_read = R53z::JsonFile.read_json(path: @filename)
    assert_equal(zone_read, @zone)
  end
end

