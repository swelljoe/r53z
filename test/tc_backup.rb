require 'test/unit'
require_relative '../lib/r53z'

class TestBackup < Test::Unit::TestCase
  def setup
    # setup a connection to AWS
    @creds = R53z::Config.new()
    @client = R53z::Client.new('default', @creds)
    # Create a randomish zone name that doesn't exist already
    @domain = 'test' + Time.now.to_i.to_s + '.com'
    @zone = { "name" => @domain, "type" => "SOA", "region" => "us-east-1", "ttl" => "1", "resource_records" => [{ "value" => "ns-895.awsdns-47.net. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"}]}
  end

  def teardown
    # delete the new domain
    zones = @client.list
    if zones.to_s.include?(@domain)
      @client.delete(@domain)
    end
  end

  # There's a lot of repetition through here. Needs a cleanup.
  def test_create
    zones = @client.list
    # Make sure it doesn't already exist
    if zones.to_s.include?(@domain)
      @client.delete(@domain)
    end
    @client.create(@zone)
    zones_after = @client.list
    assert(zones_after.to_s.include?(@domain)) # XXX This could be better
    @client.delete(@domain)
  end

  def test_delete
    # create a zone to delete
    @client.create(@zone)
    assert(zones_after.to_s.include?(@domain)) # repetitive!
    @client.delete(@domain)
  end

  def test_dump
    # Test a dump to file
  end

  def test_restore
    # Test restore from file
  end
end

