require 'test/unit'
require 'time'
require_relative '../lib/r53z'
# Test with more than 100 zones
# This is disabled, by default, because it takes a long time, and is 
# currently not expected to work. It'll let us know when we handle 100+
# zone lists correctly.

class Test101 < Test::Unit::TestCase
  def setup
    # Insure we have a credentials file configured
    # XXX Paths shouldn't be hardcoded
    @secrets = "test/data/secret-credentials"
    assert(File.exists?(@secrets), "Read/Write tests require valid credentials in test/data/secret-credentials (all tests will fail)")

    # setup a connection to AWS
    creds = R53z::Config.new(@secrets)
    @client = R53z::Client.new('default', creds)
    # Create a list of 101 zone names that don't exist already
    @domains = []
    @names = [] # A list of zones for teardown
    for i in 1..1501
      @domain = i.to_s + '-test' + Time.now.to_i.to_s + '.com.' 
      @names.push(@domain)
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
      @domains.push({:info => @zoneinfo, :records => @zonerecords})
    end
  end

  def teardown
    @names.each do |name|
      # delete the new zone, if it still exists
      unless @client.list(:name => name).empty?
        # find the delegation set, if it still exists
        dset_id = @client.get_delegation_set_id(name)
        @client.delete(name)
        # delete the delegation set once zone is gone
        @client.delete_delegation_set(id: dset_id) if dset_id
      end
    end
  end

  def test_1500
    # create 101 unique zones
    @domains.each do |domain|
      @client.create(info: domain[:info], records: domain[:records])
    end
    # Check for some of the zones existence
    # XXX There seems to be a delay in zones being listable with large
    # numbers of zones? This test intermittently fails without a delay.
    sleep 60
    assert(@client.list(name: @names[0]).any?, @names[0] + " exists.")
    assert(@client.list(name: @names[99]).any?, @names[99] + " exists.")
    assert(@client.list(name: @names[1000]).any?, @names[1000] + " exists.")
    testzones = @client.list # this is a bad idea on a real AWS account
    count = testzones.select {|z| @names.include?(z[:name])}.length
    assert(count == 1500, "We can list more than 1500 zones.")
  end
end

