# xfrtuc

A Ruby client for the [Transferatu](https://github.com/heroku/transferatu) API, used to manage data transfers, schedules, and groups.

## Installation

```ruby
gem 'xfrtuc'
```

## Usage

```ruby
client = Xfrtuc::Client.new(user: "user", password: "secret", url: "https://transferatu.example.com")

group = client.group.create("my-group", "https://log-input.example.com")
client.group("my-group").transfer.create(from_url: "postgres:///source", to_url: "postgres:///target")
client.group("my-group").transfer.list
client.group("my-group").schedule.create(name: "nightly", callback_url: "https://example.com/callback")
```

## Development

```
bundle install
bundle exec rspec
```

## License

MIT
