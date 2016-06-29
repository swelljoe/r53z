require 'test/unit'
require 'time'
require_relative '../lib/r53z'

class TestBackup < Test::Unit::TestCase
  def setup
    # Insure tmp dir exists
    @tmppath = "test/tmp"
    Dir.mkdir(@tmppath) unless Dir.exists?(@tmppath)

    # Insure we have a credentials file configured
    # XXX Paths shouldn't be hardcoded
    @secrets = "test/data/secret-credentials"
    assert(File.exists?(@secrets), "Read/Write tests requires valid credentials in test/data/secret-credentials (all tests will fail)")

    # setup a connection to AWS
    creds = R53z::Config.new(@secrets)
    @client = R53z::Client.new('default', creds)
    # Create a randomish zone name that doesn't exist already
    @domain = 'test' + Time.now.to_i.to_s + '.com'
    @subdomain = 'sub.' + @domain
    @alias = 'alias.' + @domain
    @zoneinfo = {
      :hosted_zone => {
        :name => @domain,
        :config => {
          :comment => 'R53z test zone'
        }
      }
    }
    @zonerecords = [
      {
        :name => @domain,
        :type => "A",
        :ttl => 1,
        :resource_records => [
          { :value => "192.168.100.100" },
          { :value => "192.168.111.111" },
        ]
      },
      {
        :name => @subdomain,
        :type => "A",
        :ttl => 1,
        :resource_records => [
          { :value => "192.168.200.200" },
        ]
      },
      {
        :name => @alias,
        :type => "CNAME",
        :ttl => 1,
        :resource_records => [
          { :value => @domain },
        ],
      },
      {
        :name => @domain,
        :type => "MX",
        :ttl => 1,
        :resource_records => [
          { :value => "10 " + @subdomain },
        ],
      }
    ]
  end

  def teardown
    # delete the new zone, if it still exists
    unless @client.list(:name => @domain).empty?
      # find the delegation set, if it still exists
      dset_id = @client.get_delegation_set_id(@domain)
      @client.delete(@domain)
      # delete the delegation set once zone is gone
      @client.delete_delegation_set(id: dset_id) if dset_id
    end
    # remove dump files
    if File.file?(File.join(@tmppath, @domain + ".json"))
      File.delete(File.join(@tmppath, @domain + ".json"))
    end
    if File.file?(File.join(@tmppath, @domain + ".zoneinfo.json"))
      File.delete(File.join(@tmppath, @domain + ".zoneinfo.json"))
    end
  end

  def test_client_class
    assert_instance_of(R53z::Client, @client)
  end

  def test_delete
    # create a zone to delete
    @client.create(info: @zoneinfo, records: @zonerecords)
    assert(@client.list(:name => @domain).any?) # exists? 
    @client.delete(@domain)
    assert(@client.list(:name => @domain).empty?) # now gone?
  end

  def test_dump
    # Test a dump to files
    # Should end up with a resource records file and a zone info file
    @client.create(info: @zoneinfo, records: @zonerecords)
    @client.dump(@tmppath, @domain)
    # Records file exists?
    assert(File.file?(File.join(@tmppath, @domain + ".json")))
    # Meta data file exists?
    assert(File.file?(File.join(@tmppath, @domain + ".zoneinfo.json")))
  end

  def test_restore
    # Test restore from file
    # Create zone at AWS
    @client.create(info: @zoneinfo, records: @zonerecords)
    # Dump to file
    @client.dump(@tmppath, @domain)
    # Delete from AWS
    dset_id = @client.get_delegation_set_id(@domain)
    @client.delete(@domain)
    @client.delete_delegation_set(id: dset_id) if dset_id
    sleep 1
    assert_equal(@client.list(:name => @domain), []) 
    # Restore it from file
    @client.restore(@tmppath, @domain)
    assert(@client.list(:name => @domain))
  end
end

