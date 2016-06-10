module R53z
  class Client 
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
          unless name == zone[:name]
            next
          end
        end
        rv.push({:name => zone[:name], :id => zone[:id]})
      end
      rv
    end

    # Create zone with record(s) from a hash
    def create(zone, delegation_set_id = nil)
      self.list(zone[:name]).any?
      if self.list(zone[:name]).any?
        error zone[:name] + 'exists'
      end
      zoneinfo = self.client.create_hosted_zone({
        :name => zone[:name],
        :caller_reference => 'R53-create-' + self.random_string,
        :delegation_set_id => delegation_set_id
      })
      record_sets = {
        :hosted_zone_id => zoneinfo[:hosted_zone][:id],
        :change_batch => {
          :changes => [
            {
              :action => "CREATE",
              :resource_record_set => zone
            }
          ]
        }
      }
      self.client.change_resource_record_sets(record_sets)
    end

    def delete(name)
      # get the ID
      zone_id = self.list(name).first[:id]
      client.delete_hosted_zone(:id => zone_id)
    end

    def record_list(zone_id)
      records = self.client.list_resource_record_sets(hosted_zone_id: zone_id)
      rv = []
      records[:resource_record_sets].each do |record|
        rv.push(record.to_h)
      end
      rv
    end

    def random_string(len=16)
      rand(36**len).to_s(36)
    end
  end
end

