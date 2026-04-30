# frozen_string_literal: true

require "cgi"
require "json"
require "net/http"
require "uri"
require "xfrtuc/errors"

module Xfrtuc
  class Client
    attr_reader :base_url

    def initialize(username, password, base_url = "https://transferatu.heroku.com")
      @base_url = base_url
      @username = username
      @password = password
    end

    def transfer
      @xfer_client ||= Xfrtuc::Transfer.new(self)
    end

    def schedule
      @sched_client ||= Xfrtuc::Schedule.new(self)
    end

    def group(name = nil)
      if name.nil?
        @group_client ||= Xfrtuc::Group.new(self)
      else
        self.class.new(@username, @password,
          @base_url + "/groups/#{CGI.escape(name)}",)
      end
    end

    def get(path, params = {})
      uri = build_uri(path)
      uri.query = URI.encode_www_form(params[:params]) if params[:params]
      request = Net::HTTP::Get.new(uri)
      execute(uri, request)
    end

    def post(path, data = {})
      uri = build_uri(path)
      request = Net::HTTP::Post.new(uri)
      request.body = JSON.generate(data)
      execute(uri, request)
    end

    def put(path, data = {})
      uri = build_uri(path)
      request = Net::HTTP::Put.new(uri)
      request.body = JSON.generate(data)
      execute(uri, request)
    end

    def delete(path)
      uri = build_uri(path)
      request = Net::HTTP::Delete.new(uri)
      execute(uri, request)
    end

    private

    def build_uri(path)
      URI.parse("#{@base_url}#{path}")
    end

    HTTP_ERROR_MAP = {
      400 => HTTP::BadRequest,
      404 => HTTP::NotFound,
      409 => HTTP::Conflict,
      410 => HTTP::Gone,
      503 => HTTP::ServiceUnavailable,
    }.freeze

    def execute(uri, request)
      request.basic_auth(@username, @password)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      response = http.request(request)
      status = Integer(response.code)
      unless (200..299).cover?(status)
        error_class = HTTP_ERROR_MAP.fetch(status) do
          (status >= 500) ? HTTP::ServerError : HTTP::ClientError
        end
        raise error_class, "Expected 2xx, got #{response.code}"
      end
      return nil if response.body.nil? || response.body.empty?
      JSON.parse(response.body)
    rescue Errno::ECONNRESET => e
      raise HTTP::ConnectionResetError, e.message
    rescue ::SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
      Errno::ENETUNREACH, Net::OpenTimeout, Net::ReadTimeout => e
      raise HTTP::SocketError, e.message
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
    def initialize(client)
      super
    end

    def info(name)
      client.get("/groups/#{CGI.escape(name)}")
    end

    def list
      client.get("/groups")
    end

    def create(name, log_input_url = nil)
      client.post("/groups", { name: name, log_input_url: log_input_url })
    end

    def delete(name)
      client.delete("/groups/#{CGI.escape(name)}")
    end
  end

  class Transfer < ApiEndpoint
    def initialize(client)
      super
    end

    def info(id, opts = {})
      verbose = opts.delete(:verbose) || false
      unless opts.empty?
        raise ArgumentError, "Unsupported option(s): #{opts.keys}"
      end
      client.get("/transfers/#{id}", params: { verbose: verbose })
    end

    def list
      client.get("/transfers")
    end

    def create(opts)
      from_type = opts.fetch :from_type
      from_url = opts.fetch :from_url
      to_type = opts.fetch :to_type
      to_url = opts.fetch :to_url
      [:from_type, :from_url, :to_type, :to_url].each { |key| opts.delete key }
      from_name = opts.delete :from_name
      to_name = opts.delete :to_name
      log_input_url = opts.delete :log_input_url
      num_keep = opts.delete :num_keep

      unless opts.empty?
        raise ArgumentError, "Unsupported option(s): #{opts.keys}"
      end
      payload = {
        from_type: from_type,
        from_url: from_url,
        from_name: from_name,
        to_type: to_type,
        to_url: to_url,
        to_name: to_name,
      }
      payload.merge!(log_input_url: log_input_url) unless log_input_url.nil?
      payload.merge!(num_keep: num_keep) unless num_keep.nil?
      client.post("/transfers", payload)
    end

    def delete(id)
      client.delete("/transfers/#{CGI.escape(id)}")
    end

    def cancel(id)
      client.post("/transfers/#{CGI.escape(id)}/actions/cancel")
    end

    def public_url(id, opts = {})
      client.post("/transfers/#{CGI.escape(id)}/actions/public-url", opts)
    end
  end

  class Schedule < ApiEndpoint
    def initialize(client)
      super
    end

    def info(id)
      client.get("/schedules/#{id}")
    end

    def list
      client.get("/schedules")
    end

    def create(opts)
      name = opts.fetch :name
      callback_url = opts.fetch :callback_url
      hour = opts.fetch :hour
      days = opts.fetch(:days, Date::DAYNAMES)
      timezone = opts.fetch(:timezone, "UTC")
      retain_weeks = opts.delete(:retain_weeks)
      retain_months = opts.delete(:retain_months)

      [:name, :callback_url, :hour, :days, :timezone].each { |key| opts.delete key }
      unless opts.empty?
        raise ArgumentError, "Unsupported option(s): #{opts.keys}"
      end

      sched_opts = { name: name,
                     callback_url: callback_url,
                     hour: hour,
                     days: days,
                     timezone: timezone, }
      sched_opts[:retain_weeks] = retain_weeks unless retain_weeks.nil?
      sched_opts[:retain_months] = retain_months unless retain_months.nil?

      client.put("/schedules/#{CGI.escape(name)}", sched_opts)
    end

    def delete(id)
      client.delete("/schedules/#{CGI.escape(id)}")
    end
  end
end
