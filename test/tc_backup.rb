require 'test/unit'
require_relative '../lib/r53z'

class TestBackup < Test::Unit::TestCase
  def setup
    # setup a connection to AWS
    creds = R53z::Config.new()
    @client = R53z::Client.new('default', creds)
    # Create a randomish zone name that doesn't exist already
    @domain = 'test' + Time.now.to_i.to_s + '.com'
    @zone = {
      :name => @domain,
      :type => "A",
      :ttl => 1,
      :resource_records => [
        { :value => "198.154.100.100" }
      ]
    }
    puts @zone
  end

  def teardown
    # delete the new zone, if it still exists
    unless @client.list(@domain).empty?
      @client.delete(@domain)
    end
  end

  def test_delete
    # create a zone to delete
    @client.create(@zone)
    assert(@client.list(@domain).any?) # exists? 
    @client.delete(@domain)
    assert(@client.list(@domain).empty?) # now gone?
  end

  def test_dump
    # Test a dump to file
    #dump = @client.
  end

  def test_restore
    # Test restore from file
  end
end

