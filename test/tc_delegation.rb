require "test/unit"
require_relative "../lib/r53z"

class TestDelegationSet < Test::Unit::TestCase
  def setup
    # Insure we have a credentials file configured
    # XXX Paths shouldn't be hardcoded
    @secrets = "test/data/secret-credentials"
    assert(File.exists?(@secrets), "Read/Write tests require valid credentials in test/data/secret-credentials (all tests will fail)")

    @creds  = R53z::Config.new(@secrets)
    @client = R53z::Client.new('default', @creds)

    # Create a randomish zone name that doesn't exist already
    @domain = 'test' + Time.now.to_i.to_s + '.com'
    @zoneinfo = {
      :hosted_zone => {
        :name => @domain,
        :config => {
          :comment => 'R53z test zone'
        }
      }
    }
    @zonerecords = [{
      :name => @domain,
      :type => "A",
      :ttl => 1,
      :resource_records => [
        { :value => "192.168.100.100" },
        { :value => "192.168.111.111" },
      ]
    }]

    # Create a zone
    @client.create(info: @zoneinfo, records: @zonerecords)
    @zone_id = @client.list(name: @domain).first[:id]

    # Create a delegation set
    @dset = @client.create_delegation_set(@zone_id)
  end

  def teardown
    @client.delete(@domain)
    @client.delete_delegation_set(id: @dset.delegation_set[:id])
  end

  def test_list
    resp = @client.list_delegation_sets
    assert(resp.any?, "Able to list delegation sets")
  end

  def test_get
    resp = @client.get_delegation_set(@dset.delegation_set[:id])
    # A populated name servers list? XXx needs to eventually compare known-good values
    assert(resp.delegation_set.name_servers.any?, "Able to fetch name servers from delegation set")
  end

  def test_delete
    # Create a delegation set
    deletable_set = @client.create_delegation_set()
    del_set_id = deletable_set.delegation_set[:id]
    resp = @client.delete_delegation_set({
      id: del_set_id
    })
    assert(resp.empty?, "Able to delete delegation set by ID")
    # XXX this throws an exception, but, we need to really detect deletion,
    # aside from just an empty reply, I think?
    #assert(@client.get_delegation_set(id: del_set_id).empty?)
  end

  def test_get_delegation_id
    # Find out the delegation set ID of the test zone
    # and check it against the value in @dset.
    del_set_id = @client.get_delegation_set_id(@domain)
    assert(del_set_id == @dset.delegation_set[:id], "Created delegation set ID is right")
  end
end
