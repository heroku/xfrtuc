require 'json'
require 'rest_client'

module Xfrtuc
  VERSION = "0.0.2"

  class Client
    attr_reader :base_url

    def initialize(username, password, base_url: 'https://transferatu.heroku.com')
      @base_url = base_url
      @username = username
      @password = password
      @resource = RestClient::Resource.new(base_url,
                                           user: username,
                                           password: password,
                                           headers: { content_type: 'application/json',
                                                     accept: 'application/json' })
    end

    def transfer
      @xfer_client ||= Xfrtuc::Transfer.new(self)
    end

    def schedule
      @sched_client ||= Xfrtuc::Schedule.new(self)
    end

    def group(name=nil)
      if name.nil?
        @group_client ||= Xfrtuc::Group.new(self)
      else
        self.class.new(@username, @password,
                       base_url: @base_url + "/groups/#{URI.encode(name)}")
      end
    end

    def get(path, params={})
      JSON.parse(@resource[path].get(params))
    end

    def post(path, data)
      JSON.parse(@resource[path].post(JSON.generate(data)))
    end

    def delete(path)
      JSON.parse(@resource[path].delete)
    end
  end

  class ApiEndpoint
    def initialize(client)
      @client = client
    end

    protected

    attr_reader :client
  end

  class Group < ApiEndpoint
    def initialize(client); super; end

    def info(name)
      client.get("/groups/#{URI.encode(name)}")
    end

    def list
      client.get("/groups")
    end

    def create(name, log_input_url=nil)
      client.post("/groups", { name: name, log_input_url: log_input_url })
    end

    def delete(name)
      client.delete("/groups/#{URI.encode(name)}")
    end
  end

  class Transfer < ApiEndpoint
    def initialize(client); super; end

    def info(id)
      client.get("/transfers/#{id}")
    end

    def list
      client.get("/transfers")
    end

    def create(from_type:, from_url:, from_name: nil,
               to_type:, to_url:, to_name: nil, opts: {})
      client.post("/transfers",
                  from_type: from_type,
                  from_url: from_url,
                  from_name: from_name,
                  to_type: to_type,
                  to_url: to_url,
                  to_name: to_name)
    end

    def delete(id)
      client.delete("/transfers/#{URI.encode(id)}")
    end
  end

  class Schedule < ApiEndpoint
    def initialize(client); super; end

    def info(id)
      client.get("/schedules/#{id}")
    end

    def list
      client.get("/schedules")
    end

    def create(name:, callback_url:, hour:,
               days: Date::DAYNAMES, timezone: 'UTC')
      client.post("/schedules",
                  name: name,
                  callback_url: callback_url,
                  hour: hour,
                  days: days,
                  timezone: timezone)
    end

    def delete(id)
      client.delete("/schedules/#{URI.encode(id)}")
    end
  end
end
