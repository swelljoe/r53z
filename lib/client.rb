module R53z
  class Client 
    include Methadone::CLILogging
    attr_accessor :client

    def initialize(section, creds)
      @section = section
      @creds = creds
      @client = Aws::Route53::Client.new(
        access_key_id: creds[section]['aws_access_key_id'],
        secret_access_key: creds[section]['aws_secret_access_key'],
        region: creds[section]['region']
      )
    end

    # list one or all zones by name and ID
    def list(name = nil, delegation_set_id = nil)
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
          unless name == zone['name']
            next
          end
        end
        rv.push({:name => zone['name'], :id => zone['id']})
      end
      rv
    end

    # Create zone from a hash
    def create(zone, delegation_set_id = nil)
      if self.list(zone[:name])
        error 'zone[:name] exists'
      end
      zoneinfo = self.client.create_hosted_zone({
        name: zone['name'],
        caller_reference: 'R53-create-' + Time.now.to_i.to_s,
        delegation_set_id: delegation_set_id
      })
      resp = self.client.change_resource_record_sets(
        hosted_zone_id: zoneinfo['hosted_zone']['id'],
        change_batch: {
          changes: [
            {
              action: "CREATE",
              resource_record_set: zone
            }
          ]
        }
      )
      resp
    end

    def delete(name)
      # get the ID
      zone_id = self.client.list(name).first[:id]
      resp = self.client.change_resource_record_sets(
        hosted_zone_id: zone_id,
        change_batch: {
          changes: [
            {
              action: "DELETE",
              resource_record_set: {}
            }
          ]
        }
      )
      resp
    end

    def record_list(zone_id)
      records = self.client.list_resource_record_sets(hosted_zone_id: zone_id)
      rv = []
      records[:resource_record_sets].each do |record|
        rv.push(record.to_h)
      end
      rv
    end
  end
end

