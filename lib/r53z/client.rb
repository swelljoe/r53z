module R53z
  class Client 
    include Methadone::Main
    include Methadone::CLILogging
    attr_accessor :client

    def initialize(section, creds)
      @client = Aws::Route53::Client.new(
        access_key_id: creds[section]['aws_access_key_id'],
        secret_access_key: creds[section]['aws_secret_access_key'],
        region: creds[section]['region']
      )
    end

    # list one or all zones by name and ID
    def list(name: nil, delegation_set_id: nil)
      begin
        zones = self.client.list_hosted_zones(
          delegation_set_id: delegation_set_id
          )['hosted_zones']
      rescue Aws::Route53::Errors::ServiceError
        error "Failed to list zones" # XXX How do we get AWS error message out of it?
      end

      rv = []
      zones.each do |zone|
        if name
          unless name[-1] == '.'
            name = name + '.'
          end
          unless name == zone[:name]
            next
          end
        end
        rv.push({:name => zone[:name], :id => zone[:id]})
      end
      rv
    end

    # Create zone with record(s) from an info and records hash
    def create(info:, records:)
      #if self.list(info[:name]).any?
      #  error(info[:name] + "exists")
      #end
      # XXX: AWS sends out a data structure with config:, but expects
      # hosted_zone_config on create/restore. argh.
      # XXX: also, private_zone is not accepted here for some reason
      zone_resp = self.client.create_hosted_zone({
        :name => info[:name],
        :caller_reference => 'r53z-create-' + self.random_string,
        :delegation_set_id => info[:delegation_set_id] || options['delegation-set-id'],
        :hosted_zone_config => {
          :comment => info[:config][:comment]
        }
      })
      records.each do |record|
        # skip these, as they are handled separately (delegation set?)
        unless (record[:type] == "NS" || record[:type] == "SOA")
          self.client.change_resource_record_sets({
            :hosted_zone_id => zone_resp[:hosted_zone][:id],
            :change_batch => {
              :changes => [
                {
                  :action => "CREATE",
                  :resource_record_set => record
                }
              ]
            }
          })
        end
      end
    end

    # delete a zone by name
    def delete(name)
      # get the ID
      zone_id = self.list(:name => name).first[:id]
      self.delete_all_rr_sets(zone_id)
      client.delete_hosted_zone(:id => zone_id)
    end

    # delete all of the resource record sets in a zone (this is required to delete
    # a zone
    def delete_all_rr_sets(zone_id)
      self.record_list(zone_id).reject do |rs|
        (rs[:type] == "NS" || rs[:type] == "SOA")
      end.each do |record_set|
        self.client.change_resource_record_sets({
          :hosted_zone_id => zone_id,
          :change_batch => {
            :changes => [{
              :action=> "DELETE",
              :resource_record_set => record_set
            }]
          }
        })
      end
    end

    # dump a zone to a direcory. Will generate two files; a zoneinfo file and a 
    # records file.
    def dump(dirpath, name)
      # Get the ID
      zone_id = self.list(:name => name).first[:id]

      # normalize name
      unless name[-1] == '.'
        name = name + '.'
      end
      # dump the record sets
      R53z::JsonFile.write_json(
        path: File.join(dirpath, name),
        data: self.record_list(zone_id))
      # Dump the zone metadata
      R53z::JsonFile.write_json(
        path: File.join(dirpath, name + "zoneinfo"),
        data: self.client.get_hosted_zone({
          :id => zone_id}).hosted_zone.to_h)
    end

    # Restore a zone from the given path. It expects files named
    # zone.zoneinfo.json and zone.json
    def restore(path, domain)
      # normalize domain
      unless domain[-1] == '.'
        domain = domain + '.'
      end
      # Load up the zone info file
      file = File.join(path, domain)
      info = R53z::JsonFile.read_json(path: file + "zoneinfo")
      records = R53z::JsonFile.read_json(path: file)
      self.create(:info => info, :records => records)
    end

    def record_list(zone_id)
      records = self.client.list_resource_record_sets(hosted_zone_id: zone_id)
      rv = []
      records[:resource_record_sets].each do |record|
        rv.push(record.to_h)
      end
      rv
    end

    # create a new delegation set, optionally associated with an existing zone
    def create_delegation_set(zone_id = nil)
      self.client.create_reusable_delegation_set({
        caller_reference: 'r53z-create-del-set-' + self.random_string,
        hosted_zone_id: zone_id
      })
    end

    # list all delegation sets
    def list_delegation_sets
      resp = self.client.list_reusable_delegation_sets({})
      return resp.delegation_sets
    end
    
    # get details of a delegation set specified by ID, incuding name servers
    def get_delegation_set(id:)
      self.client.get_reusable_delegation_set({
        id: id
      })
    end

    # delete a delegation set by ID
    def delete_delegation_set(id:)
      self.client.delete_reusable_delegation_set({
        id: id
      })
    end

    # Get delegation set ID for the give zone
    def get_delegation_set_id(name:)
      zone_id = self.list(:name => name).first[:id]
      self.client.get_hosted_zone({
        id: zone_id 
      }).delegation_set[:id]
    end

    # random string generator helper function
    def random_string(len=16)
      rand(36**len).to_s(36)
    end
  end
end

