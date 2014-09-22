require 'securerandom'
require 'spec_helper'
require 'sham_rack'

module Xfrtuc
  User = Struct.new(:name, :password)
  class FakeTransferatu
    attr_reader :groups

    def headers
      { content_type: 'application/json' }
    end

    def initialize(*users)
      @groups = []
      @transfers = {}
      @schedules = {}
      @users = users
    end

    def active_groups
      @groups.reject { |g| g[:deleted] }
    end

    def find_transfer(group_name, &block)
      @transfers[group_name].find(&block)
    end

    def last_transfer(group_name)
      @transfers[group_name].last
    end

    def last_schedule(group_name)
      @schedules[group_name].last
    end

    def add_group(name, log_url=nil)
      existing_group = @groups.find { |g| g[:name] == name }
      if existing_group
        if existing_group[:deleted]
          # undelete
          existing_group.delete(:deleted)
          [201, headers, [ existing_group.to_json ] ]
        else
          [409, headers, [ { id: :conflict, message: "group #{name} already exists" }.to_json ] ]
        end
      else
        group = { name: name, log_input_url: log_url }
        @groups << group
        @transfers[name] = []
        @schedules[name] = []
        [201, headers, [ group.to_json ] ]
      end
    end

    def delete_group(name)
      target = @groups.find { |g| g[:name] == name }
      if target && target[:deleted]
        [410, headers, []]
      elsif target.nil?
        [404, headers, []]
      else
        target[:deleted] = true
        [200, headers, [target.to_json]]
      end
    end

    def list_groups
      [200, headers, [@groups.to_json]]
    end

    def get_group(name)
      [200, headers, [@groups.find { |g| g[:name] == name }.to_json]]
    end

    def list_transfers(group_name)
      group = @groups.find { |g| g[:name] == group_name }
      if group.nil?
        [404, headers, []]
      elsif group[:deleted]
        [410, headers, []]
      else
        transfers = @transfers[group_name]
        [200, headers, [transfers.to_json]]
      end
    end

    def get_transfer(group_name, xfer_id, verbose=false)
      group = @groups.find { |g| g[:name] == group_name }
      if group.nil?
        [404, headers, []]
      elsif group[:deleted]
        [409, headers, []]
      else
        transfer = @transfers[group_name].find { |xfer| xfer[:uuid] == xfer_id }
        if verbose
          result = transfer.dup
          result[:logs] = []
          transfer = result
        end
        [200, headers, [transfer.to_json]]
      end
    end

    def add_transfer(group_name, transfer)
      unless @transfers.has_key? group_name
        return [404, headers, []]
      end
      xfer = { uuid: SecureRandom.uuid }
      %w(from_type from_url from_name to_type to_url to_name).each do |key|
        xfer[key.to_sym] = transfer[key]
      end

      @transfers[group_name] << xfer
      [201, {}, [xfer.to_json]]
    end

    def delete_transfer(group_name, xfer_id)
      unless @transfers.has_key? group_name
        return [404, headers, []]
      end
      xfer = @transfers[group_name].find { |item| item[:uuid] == xfer_id }
      if xfer.nil?
        return [404, headers, []]
      else
        @transfers[group_name].delete xfer
        return [200, headers, [ xfer.to_json ]]
      end
    end

    def add_schedule(group_name, schedule)
      unless @schedules.has_key? group_name
        return [404, headers, []]
      end
      sched = { uuid: SecureRandom.uuid }
      %w(name callback_url days hour timezone).each do |key|
        sched[key.to_sym] = schedule[key]
      end
      @schedules[group_name] << sched
      [201, {}, [sched.to_json]]
    end

    def delete_schedule(group_name, schedule_id)
      unless @schedules.has_key? group_name
        return [404, headers, []]
      end
      schedule = @schedules[group_name].find { |item| item[:uuid] == schedule_id }
      if schedule.nil?
        return [404, headers, []]
      else
        @schedules[group_name].delete schedule
        return [200, headers, [ schedule.to_json ]]
      end
    end

    def list_schedules(group_name)
      group = @groups.find { |g| g[:name] == group_name }
      if group.nil?
        [404, headers, []]
      elsif group[:deleted]
        [410, headers, []]
      else
        schedules = @schedules[group_name]
        [200, headers, [schedules.to_json]]
      end
    end

    def get_schedule(group_name, sched_id)
      group = @groups.find { |g| g[:name] == group_name }
      if group.nil?
        [404, headers, []]
      elsif group[:deleted]
        [410, headers, []]
      else
        sched = @schedules[group_name].find { |s| s[:uuid] == sched_id }
        if sched.nil?
          [404, headers, []]
        else
          [200, headers, [sched.to_json]]
        end
      end
    end

    def call(env)
      unless verify_auth(env)
        return [401, headers, ["Not authorized"]]
      end
      case path(env)
      when %r{/groups/[^/]+/transfers} then
        transfers_endpoint(env)
      when %r{/groups/[^/]+/schedules} then
        schedules_endpoint(env)
      when %r{/groups} then
        groups_endpoint(env)
      else
        [404, headers, []]
      end
    end

    def transfers_endpoint(env)
      path = path(env)
      group_name, xfer_id = path.match(%r{\A/groups/(.*)/transfers(?:/(.*))?\z}) && [$1, $2]
      verb = verb(env)
      if verb == 'POST'
        body = body(env)
        xfer = JSON.parse(body)
        unless xfer_id.nil?
          [405, headers, []]
        end
        add_transfer(group_name, xfer)
      elsif verb == 'DELETE'
        unless group_name && xfer_id
          return [404, headers, []]
        end
        delete_transfer(group_name, xfer_id)
      elsif verb == 'GET'
        if xfer_id.nil?
          list_transfers(group_name)
        else
          get_transfer(group_name, xfer_id, params(env)['verbose'] == 'true')
        end
      else
        [405, headers, []]
      end
    end

    def groups_endpoint(env)
      path = path(env)
      verb = verb(env)

      group_name = path.match(%r{\A/groups/(.*)\z}) && $1

      if verb == 'GET'
        if group_name.nil?
          list_groups
        else
          get_group(group_name)
        end
      elsif verb == 'POST'
        body = body(env)
        data = JSON.parse(body)
        add_group(data["name"], data["log_input_url"])
      elsif verb == 'DELETE'
        name = path.match(%r{\A/groups/(.*)\z}) && $1
        unless name
          return [404, headers, []]
        end
        delete_group(name)
      else
        [405, headers, []]
      end
    end

    def schedules_endpoint(env)
      path = path(env)
      group_name, sched_id = path.match(%r{\A/groups/(.*)/schedules(?:/(.*))?\z}) && [$1, $2]
      verb = verb(env)
      if verb == 'POST'
        body = body(env)
        sched = JSON.parse(body)
        unless sched_id.nil?
          [405, headers, []]
        end
        add_schedule(group_name, sched)
      elsif verb == 'DELETE'
        unless group_name && sched_id
          return [404, headers, []]
        end
        delete_schedule(group_name, sched_id)
      elsif verb == 'GET'
        if sched_id.nil?
          list_schedules(group_name)
        else
          get_schedule(group_name, sched_id)
        end
      else
        [405, headers, []]
      end
    end

    private
    def verify_auth(env)
      auth = Rack::Auth::Basic::Request.new(env)
      if auth.provided? && auth.basic?
        user, password = auth.credentials
        @users.any? { |u| u.name == user && u.password == password }
      end
    end

    def path(rack_env)
      rack_env['PATH_INFO']
    end

    def verb(rack_env)
      rack_env['REQUEST_METHOD']
    end

    def params(rack_env)
      Rack::Utils.parse_nested_query rack_env['QUERY_STRING']
    end

    def body(rack_env)
      raw_body = rack_env["rack.input"].read
      rack_env["rack.input"].rewind
      raw_body
    end
  end

  describe Client do
    let(:username) { 'reginald' }
    let(:password) { 'hunter2' }
    let(:client)   { Client.new(username, password) }

    describe "#group" do
      context "with an argument" do
        let(:group_name) { 'foo' }

        it "returns a new client rooted at that group's base URL" do
          group_client = client.group(group_name)
          expect(group_client).to be_instance_of(Client)
          expect(group_client.base_url).to eq(client.base_url +
                                              "/groups/#{URI.encode(group_name)}")
        end
      end

      context "without an argument" do
        it "returns a group client" do
          expect(client.group).to be_instance_of(Group)
        end
      end
    end

    describe "#transfer" do
      it "returns a transfer client" do
        expect(client.transfer).to be_instance_of(Transfer)
      end
    end

    describe "#schedule" do
      it "returns a schedule client" do
        expect(client.schedule).to be_instance_of(Schedule)
      end
    end
  end

  describe "api interactions" do
    let(:username)    { 'vivian' }
    let(:password)    { 'hunter2' }
    let(:user)        { User.new(username, password) }
    let(:fakesferatu) { FakeTransferatu.new(user) }
    let(:host)        { 'transferatu.example.com' }
    let(:client)      { Client.new(username, password, "https://#{host}") }

    before do
      ShamRack.mount(fakesferatu, host, 443)
    end

    after do
      ShamRack.unmount_all
    end

    describe Group do
      let(:group_name)    { "edna" }
      let(:log_input_url) { "https://token:t.foo@logplex.example.com/logs" }

      describe "#create" do
        it "creates a new group" do
          client.group.create("edna", log_input_url)
          group = fakesferatu.groups.last
          expect(group[:name]).to eq(group_name)
          expect(group[:log_input_url]).to eq(log_input_url)
        end
      end

      describe "#list" do
        before do
          fakesferatu.add_group('g1')
          fakesferatu.add_group('g2')
        end

        it "lists existing groups" do
          result = client.group.list
          expect(result.count).to eq(2)
          expect(result.first["name"]).to eq('g1')
          expect(result.last["name"]).to eq('g2')
        end
      end

      describe "#info" do
        before do
          fakesferatu.add_group(group_name, log_input_url)
        end

        it "returns details for the given group" do
          info = client.group.info(group_name)
          expect(info["name"]).to eq(group_name)
          expect(info["log_input_url"]).to eq(log_input_url)
        end
      end

      describe "#delete" do
        before do
          fakesferatu.add_group(group_name, log_input_url)
        end

        it "deletes the given group" do
          client.group.delete(group_name)
          deleted_group = fakesferatu.groups.find { |g| g[:name] == group_name }
          expect(deleted_group[:deleted]).to be true
        end
      end
    end

    describe Transfer do
      let(:g)         { "edna" }
      let(:xfer_data) { { from_url: 'postgres:///test1',
                         from_name: 'earl', from_type: 'pg_dump',
                         to_url: 'postgres:///test2',
                         to_name: 'mildred', to_type: 'pg_restore' } }

      before do
        fakesferatu.add_group(g)
      end

      describe "#create" do
        it "creates a new transfer" do
          client.group(g).transfer.create(xfer_data)
          xfer = fakesferatu.last_transfer(g)
          xfer_data.each do |k,v|
            expect(xfer[k]).to eq(v)
          end
        end
      end

      describe "#list" do
        before do
          2.times { fakesferatu.add_transfer(g, Hash[xfer_data.map { |k, v| [k.to_s, v] }]) }
        end

        it "lists existing transfers" do
          xfers = client.group(g).transfer.list
          expect(xfers.count).to eq(2)
          xfers.each do |xfer|
            xfer_data.each do |k,v|
              expect(xfer[k.to_s]).to eq(v)
            end
          end
        end
      end

      describe "#info" do
        before do
          fakesferatu.add_transfer(g, Hash[xfer_data.map { |k, v| [k.to_s, v] }])
        end

        it "gets info for an existing transfer" do
          id = fakesferatu.last_transfer(g)[:uuid]
          xfer = client.group(g).transfer.info(id)
          xfer_data.each do |k,v|
            expect(xfer[k.to_s]).to eq(v)
          end
          expect(xfer["logs"]).to be_nil
        end

        it "includes logs when verbose mode is requested" do
          id = fakesferatu.last_transfer(g)[:uuid]
          xfer = client.group(g).transfer.info(id, verbose: true)
          xfer_data.each do |k,v|
            expect(xfer[k.to_s]).to eq(v)
          end
          expect(xfer["logs"]).not_to be_nil
        end
      end

      describe "#delete" do
        before do
          fakesferatu.add_transfer(g, Hash[xfer_data.map { |k, v| [k.to_s, v] }])
        end

        it "deletes the given transfer" do
          id = fakesferatu.last_transfer(g)[:uuid]
          client.group(g).transfer.delete(id)
          expect(fakesferatu.last_transfer(g)).to be_nil
        end
      end
    end

    describe Schedule do
      let(:g)          { "edna" }
      let(:sched_data) { { name: 'my schedule',
                          callback_url: 'https://example.com/callback/foo',
                          hour: 13,
                          days: Date::DAYNAMES,
                          timezone: 'UTC' } }

      before do
        fakesferatu.add_group(g)
      end

      describe "#create" do
        it "creates a new schedule" do
          client.group(g).schedule.create(sched_data)
          sched = fakesferatu.last_schedule(g)
          sched_data.each do |k,v|
            expect(sched[k]).to eq(v)
          end
        end
      end

      describe "#list" do
        before do
          2.times { fakesferatu.add_schedule(g, Hash[sched_data.map { |k, v| [k.to_s, v] }]) }
        end

        it "lists existing schedules" do
          scheds = client.group(g).schedule.list
          expect(scheds.count).to eq(2)
          scheds.each do |sched|
            sched_data.each do |k,v|
              expect(sched[k.to_s]).to eq(v)
            end
          end
        end
      end

      describe "#info" do
        before do
          fakesferatu.add_schedule(g, Hash[sched_data.map { |k, v| [k.to_s, v] }])
        end

        it "gets info for an existing schedule" do
          id = fakesferatu.last_schedule(g)[:uuid]
          sched = client.group(g).schedule.info(id)
          sched_data.each do |k,v|
            expect(sched[k.to_s]).to eq(v)
          end
        end
      end

      describe "#delete" do
        before do
          fakesferatu.add_schedule(g, Hash[sched_data.map { |k, v| [k.to_s, v] }])
        end

        it "deletes the given schedule" do
          id = fakesferatu.last_schedule(g)[:uuid]
          client.group(g).schedule.delete(id)
          expect(fakesferatu.last_schedule(g)).to be_nil
        end
      end
    end
  end
end
