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

    # Create zone with record(s) from an info and records hash
    def create(info:, records:)
      self.list(info[:name]).any?
      if self.list(info[:name]).any?
        error info[:name] + 'exists'
      end
      zoneresp = self.client.create_hosted_zone({
        :name => info[:name],
        :caller_reference => info[:caller_reference] ||
          'r53z-create-' + self.random_string,
        :delegation_set_id => info[:delegation_set_id],
        :hosted_zone_config => info[:hosted_zone_config]
      })
      record_sets = {
        :hosted_zone_id => zoneresp[:hosted_zone][:id],
        :change_batch => {
          :changes => [
            {
              :action => "CREATE",
              :resource_record_set => records
            }
          ]
        }
      }
      self.client.change_resource_record_sets(record_sets)
    end

    def delete(name)
      # get the ID
      zone_id = self.list(name).first[:id]
      self.delete_all_rr_sets(zone_id)
      client.delete_hosted_zone(:id => zone_id)
    end

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

    def dump(dirpath, name)
      # Get the ID
      zone_id = self.list(name).first[:id]
      # dump the record sets
      R53z::JsonFile.write_json(
        path: File.join(dirpath, name),
        data: self.record_list(zone_id))
      # Dump the zone metadata
      R53z::JsonFile.write_json(
        path: File.join(dirpath, name + ".zoneinfo"),
        data: self.client.list_hosted_zones_by_name({
          :dns_name => name,
          :hosted_zone_id => zone_id,
          :max_items => 1})[0][0].to_h)
    end

    def restore(path)
      # Load up the zone info file
      info = R53z::JsonFile.read_json(path + "zoneinfo.json")
      puts info
      records = R53z::JsonFile.read_json(path + ".json")
      puts records
      self.create(info: info, records: records)
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

