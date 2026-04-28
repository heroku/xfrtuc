require 'securerandom'
require 'spec_helper'

module Xfrtuc
  RSpec.describe Client do
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
                                              "/groups/#{CGI.escape(group_name)}")
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

  RSpec.describe "api interactions" do
    let(:username) { 'vivian' }
    let(:password) { 'hunter2' }
    let(:host)     { 'transferatu.example.com' }
    let(:base_url) { "https://#{host}" }
    let(:client)   { Client.new(username, password, base_url) }

    describe Group do
      let(:group_name)    { "edna" }
      let(:log_input_url) { "https://token:t.foo@logplex.example.com/logs" }

      describe "#create" do
        it "creates a new group" do
          WebMock.stub_request(:post, "#{base_url}/groups")
            .with(basic_auth: [username, password],
                  body: { name: group_name, log_input_url: log_input_url })
            .to_return_json(status: 201,
                            body: { name: group_name, log_input_url: log_input_url })

          result = client.group.create(group_name, log_input_url)
          expect(result["name"]).to eq(group_name)
          expect(result["log_input_url"]).to eq(log_input_url)
        end
      end

      describe "#list" do
        it "lists existing groups" do
          groups = [{ name: 'g1' }, { name: 'g2' }]
          WebMock.stub_request(:get, "#{base_url}/groups")
            .with(basic_auth: [username, password])
            .to_return_json(status: 200, body: groups)

          result = client.group.list
          expect(result.count).to eq(2)
          expect(result.first["name"]).to eq('g1')
          expect(result.last["name"]).to eq('g2')
        end
      end

      describe "#info" do
        it "returns details for the given group" do
          group = { name: group_name, log_input_url: log_input_url }
          WebMock.stub_request(:get, "#{base_url}/groups/#{group_name}")
            .with(basic_auth: [username, password])
            .to_return_json(status: 200, body: group)

          info = client.group.info(group_name)
          expect(info["name"]).to eq(group_name)
          expect(info["log_input_url"]).to eq(log_input_url)
        end
      end

      describe "#delete" do
        it "deletes the given group" do
          WebMock.stub_request(:delete, "#{base_url}/groups/#{group_name}")
            .with(basic_auth: [username, password])
            .to_return_json(status: 200, body: { name: group_name, deleted: true })

          result = client.group.delete(group_name)
          expect(result["name"]).to eq(group_name)
        end
      end
    end

    describe Transfer do
      let(:g)         { "edna" }
      let(:xfer_data) { { from_url: 'postgres:///test1',
                         from_name: 'earl', from_type: 'pg_dump',
                         to_url: 'postgres:///test2',
                         to_name: 'mildred', to_type: 'pg_restore' } }
      let(:xfer_id)   { SecureRandom.uuid }

      describe "#create" do
        it "creates a new transfer" do
          response = xfer_data.merge(uuid: xfer_id)
          WebMock.stub_request(:post, "#{base_url}/groups/#{g}/transfers")
            .with(basic_auth: [username, password])
            .to_return_json(status: 201, body: response)

          result = client.group(g).transfer.create(xfer_data)
          xfer_data.each do |k, v|
            expect(result[k.to_s]).to eq(v)
          end
        end

        it "accepts an optional log_input_url" do
          log_url = "https://example.com/logs"
          response = xfer_data.merge(uuid: xfer_id, log_input_url: log_url)
          WebMock.stub_request(:post, "#{base_url}/groups/#{g}/transfers")
            .with(basic_auth: [username, password],
                  body: hash_including("log_input_url" => log_url))
            .to_return_json(status: 201, body: response)

          result = client.group(g).transfer.create(xfer_data.merge(log_input_url: log_url))
          expect(result["log_input_url"]).to eq(log_url)
        end

        it "accepts an optional num_keep" do
          num_keep = 3
          response = xfer_data.merge(uuid: xfer_id, num_keep: num_keep)
          WebMock.stub_request(:post, "#{base_url}/groups/#{g}/transfers")
            .with(basic_auth: [username, password],
                  body: hash_including("num_keep" => num_keep))
            .to_return_json(status: 201, body: response)

          result = client.group(g).transfer.create(xfer_data.merge(num_keep: num_keep))
          expect(result["num_keep"]).to eq(num_keep)
        end

        it "raises ArgumentError for unsupported options" do
          expect {
            client.group(g).transfer.create(xfer_data.merge(bogus: 'value'))
          }.to raise_error(ArgumentError, /Unsupported option/)
        end
      end

      describe "#list" do
        it "lists existing transfers" do
          xfers = 2.times.map { xfer_data.merge(uuid: SecureRandom.uuid) }
          WebMock.stub_request(:get, "#{base_url}/groups/#{g}/transfers")
            .with(basic_auth: [username, password])
            .to_return_json(status: 200, body: xfers)

          result = client.group(g).transfer.list
          expect(result.count).to eq(2)
          result.each do |xfer|
            xfer_data.each do |k, v|
              expect(xfer[k.to_s]).to eq(v)
            end
          end
        end
      end

      describe "#info" do
        it "gets info for an existing transfer" do
          response = xfer_data.merge(uuid: xfer_id)
          WebMock.stub_request(:get, "#{base_url}/groups/#{g}/transfers/#{xfer_id}")
            .with(basic_auth: [username, password],
                  query: { "verbose" => "false" })
            .to_return_json(status: 200, body: response)

          xfer = client.group(g).transfer.info(xfer_id)
          xfer_data.each do |k, v|
            expect(xfer[k.to_s]).to eq(v)
          end
          expect(xfer["logs"]).to be_nil
        end

        it "includes logs when verbose mode is requested" do
          response = xfer_data.merge(uuid: xfer_id, logs: [])
          WebMock.stub_request(:get, "#{base_url}/groups/#{g}/transfers/#{xfer_id}")
            .with(basic_auth: [username, password],
                  query: { "verbose" => "true" })
            .to_return_json(status: 200, body: response)

          xfer = client.group(g).transfer.info(xfer_id, verbose: true)
          xfer_data.each do |k, v|
            expect(xfer[k.to_s]).to eq(v)
          end
          expect(xfer["logs"]).not_to be_nil
        end

        it "raises ArgumentError for unsupported options" do
          expect {
            client.group(g).transfer.info(xfer_id, bogus: 'value')
          }.to raise_error(ArgumentError, /Unsupported option/)
        end
      end

      describe "#delete" do
        it "deletes the given transfer" do
          response = xfer_data.merge(uuid: xfer_id)
          WebMock.stub_request(:delete, "#{base_url}/groups/#{g}/transfers/#{xfer_id}")
            .with(basic_auth: [username, password])
            .to_return_json(status: 200, body: response)

          result = client.group(g).transfer.delete(xfer_id)
          expect(result["uuid"]).to eq(xfer_id)
        end
      end

      describe "#cancel" do
        it "cancels the given transfer" do
          now = Time.now
          WebMock.stub_request(:post, "#{base_url}/groups/#{g}/transfers/#{xfer_id}/actions/cancel")
            .with(basic_auth: [username, password])
            .to_return_json(status: 201, body: { canceled_at: now })

          cancel_data = client.group(g).transfer.cancel(xfer_id)
          canceled_at = Time.parse(cancel_data["canceled_at"])
          expect(canceled_at).to be_within(60).of(now)
        end
      end

      describe "#public_url" do
        it "provides a public url for the given transfer" do
          url = "https://example.com/backup/#{xfer_id}"
          expires_at = Time.now + (10 * 60)
          WebMock.stub_request(:post, "#{base_url}/groups/#{g}/transfers/#{xfer_id}/actions/public-url")
            .with(basic_auth: [username, password])
            .to_return_json(status: 201, body: { url: url, expires_at: expires_at })

          url_data = client.group(g).transfer.public_url(xfer_id)
          expect { URI.parse(url_data["url"]) }.not_to raise_error
        end

        it "supports an optional ttl parameter" do
          url = "https://example.com/backup/#{xfer_id}"
          now = Time.now
          expires_at = now + (5 * 60)
          WebMock.stub_request(:post, "#{base_url}/groups/#{g}/transfers/#{xfer_id}/actions/public-url")
            .with(basic_auth: [username, password],
                  body: { ttl: 300 }.to_json)
            .to_return_json(status: 201, body: { url: url, expires_at: expires_at })

          url_data = client.group(g).transfer.public_url(xfer_id, ttl: 5 * 60)
          expires = Time.parse(url_data["expires_at"])
          expect(expires).to be_within(60).of(now + (5 * 60))
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
      let(:sched_id)   { SecureRandom.uuid }

      describe "#create" do
        it "creates a new schedule" do
          response = sched_data.merge(uuid: sched_id)
          WebMock.stub_request(:put, "#{base_url}/groups/#{g}/schedules/#{CGI.escape(sched_data[:name])}")
            .with(basic_auth: [username, password])
            .to_return_json(status: 201, body: response)

          result = client.group(g).schedule.create(sched_data)
          sched_data.each do |k, v|
            expect(result[k.to_s]).to eq(v)
          end
        end

        it "accepts an optional retain_weeks and retain_months" do
          retain_weeks = 7
          retain_months = 8
          response = sched_data.merge(uuid: sched_id, retain_weeks: retain_weeks, retain_months: retain_months)
          WebMock.stub_request(:put, "#{base_url}/groups/#{g}/schedules/#{CGI.escape(sched_data[:name])}")
            .with(basic_auth: [username, password],
                  body: hash_including("retain_weeks" => retain_weeks, "retain_months" => retain_months))
            .to_return_json(status: 201, body: response)

          result = client.group(g).schedule.create(sched_data.merge(retain_weeks: retain_weeks, retain_months: retain_months))
          expect(result["retain_weeks"]).to eq(retain_weeks)
          expect(result["retain_months"]).to eq(retain_months)
        end

        it "raises ArgumentError for unsupported options" do
          expect {
            client.group(g).schedule.create(sched_data.merge(bogus: 'value'))
          }.to raise_error(ArgumentError, /Unsupported option/)
        end
      end

      describe "#list" do
        it "lists existing schedules" do
          scheds = 2.times.map { sched_data.merge(uuid: SecureRandom.uuid) }
          WebMock.stub_request(:get, "#{base_url}/groups/#{g}/schedules")
            .with(basic_auth: [username, password])
            .to_return_json(status: 200, body: scheds)

          result = client.group(g).schedule.list
          expect(result.count).to eq(2)
          result.each do |sched|
            sched_data.each do |k, v|
              expect(sched[k.to_s]).to eq(v)
            end
          end
        end
      end

      describe "#info" do
        it "gets info for an existing schedule" do
          response = sched_data.merge(uuid: sched_id)
          WebMock.stub_request(:get, "#{base_url}/groups/#{g}/schedules/#{sched_id}")
            .with(basic_auth: [username, password])
            .to_return_json(status: 200, body: response)

          sched = client.group(g).schedule.info(sched_id)
          sched_data.each do |k, v|
            expect(sched[k.to_s]).to eq(v)
          end
        end
      end

      describe "#delete" do
        it "deletes the given schedule" do
          response = sched_data.merge(uuid: sched_id)
          WebMock.stub_request(:delete, "#{base_url}/groups/#{g}/schedules/#{sched_id}")
            .with(basic_auth: [username, password])
            .to_return_json(status: 200, body: response)

          result = client.group(g).schedule.delete(sched_id)
          expect(result["uuid"]).to eq(sched_id)
        end
      end
    end
  end
end
