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

```shell
bundle install
bundle exec rspec
```

## Releasing

1. **Bump the version** in `lib/xfrtuc/version.rb`

2. **Update `CHANGELOG.md`** — move entries from `[Unreleased]` into a new versioned section and update the comparison links at the bottom

3. **Commit the changes**

   ```shell
   git add lib/xfrtuc/version.rb CHANGELOG.md
   git commit -m "version -> x.y.z"
   ```

4. **Create and push a git tag**

   ```shell
   git tag vx.y.z
   git push origin main --tags
   ```

5. **Build and push the gem to RubyGems.org**

   ```shell
   gem build
   gem push xfrtuc-x.y.z.gem
   ```

## License

MIT
