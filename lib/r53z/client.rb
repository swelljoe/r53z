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
      if zones
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
      end
      rv
    end

    # Create zone with record(s) from an info and records hash
    def create(info:, records: nil)
      rv = {} # pile up the responses in a single hash
      #if self.list(info[:name]).any?
      #  error(info[:name] + "exists")
      #end
      # XXX: AWS sends out a data structure with config:, but expects
      # hosted_zone_config on create/restore. argh.
      # XXX: also, private_zone is not accepted here for some reason
      zone = info[:hosted_zone]
      # Populate a zone_data hash with options for zone creation
      zone_data = {}
      zone_data[:name] = zone[:name]
      zone_data[:caller_reference] = 'r53z-create-' + self.random_string
      if zone[:config] and zone[:config][:comment]
        zone_data[:hosted_zone_config] = {}
        zone_data[:hosted_zone_config][:comment] = zone[:config][:comment]
      end
      if info[:delegation_set] and info[:delegation_set][:id]
        zone_data[:delegation_set_id] = info[:delegation_set][:id]
      end
      zone_resp = self.client.create_hosted_zone(zone_data)
      rv[:hosted_zone_resp] = zone_resp

      rv[:record_set_resp] = []
      # Optionally populate records
      if records
        records.each do |record|
          # skip these, as they are handled separately (delegation set?)
          unless (record[:type] == "NS" || record[:type] == "SOA")
            record_resp = self.client.change_resource_record_sets({
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
            rv[:record_set_resp].push(record_resp)
          end
        end
      end
      return rv
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
      self.list_records(zone_id).reject do |rs|
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
        data: self.list_records(zone_id))

      # Dump the zone metadata, plus the delegated set info
      out = { :hosted_zone => 
                self.client.get_hosted_zone({ :id => zone_id}).hosted_zone.to_h,
              :delegation_set => 
                self.client.get_hosted_zone({:id => zone_id}).delegation_set.to_h
            }

      R53z::JsonFile.write_json(
        path: File.join(dirpath, name + "zoneinfo"),
        data: out)
        #data: self.client.get_hosted_zone({
        #  :id => zone_id}).hosted_zone.to_h)
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
      # create the zone and the record sets
      self.create(:info => info, :records => records)
    end

    def list_records(zone_id)
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
    def get_delegation_set(id)
      self.client.get_reusable_delegation_set({
        id: id
      })
    end

    # delete a delegation set by ID or name
    def delete_delegation_set(id: nil, name: nil)
      if name and not id
        id = get_delegation_set_id(name)
      end
      self.client.delete_reusable_delegation_set({
        id: id
      })
    end

    # Get delegation set ID for the given zone
    def get_delegation_set_id(name)
      begin
        zone_id = self.list(:name => name).first[:id]
      rescue
        return nil
      end
      return self.client.get_hosted_zone({
        id: zone_id 
      }).delegation_set[:id]
    end

    # Get the zone id from name
    def get_zone_id(name)
      return self.list(:name => name).first[:id]
    end

    # random string generator helper function
    def random_string(len=16)
      rand(36**len).to_s(36)
    end
  end
end

