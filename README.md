# Secrets Vault

A vault for storing and retrieving secrets securely.

Secrets Vault provides a simple and secure way to manage secrets in your Ruby
applications. It supports both encrypted and plaintext storage vaults.

## Common Use Cases

SecretsVault is perfect for scenarios where you need secure, local secret storage:

- **Game Development**: Store save data and player progress securely without exposing sensitive information.
- **Gem Development**: Allow users to store API tokens and credentials via your gem's CLI instead of relying on environment variables.
- **Credentials**: Get [Rails credentials]-like functionality outside of Rails applications.

[Rails credentials]: https://guides.rubyonrails.org/security.html#custom-credentials

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add secrets_vault
```

Or install it directly:

```bash
gem install secrets_vault
```

## Usage

### Encrypted Vault (Recommended)

The encrypted file adapter stores secrets in password-protected, encrypted
files. This is the recommended approach for production environments and
sensitive data.

```ruby
require "secrets_vault"

# Create a new encrypted vault
vault = SecretsVault.new("my_app", adapter: :encrypted_file)

# Store a secret (you'll be prompted for a password)
vault.store("DATABASE_URL", "postgresql://user:pass@localhost/myapp")
vault.store("API_KEY", "sk-1234567890abcdef")

# Retrieve a secret (you'll be prompted for the password)
database_url = vault.fetch("DATABASE_URL")
api_key = vault.fetch("API_KEY")
```

### Plaintext Vault

The plaintext vault stores secrets in unencrypted JSON files. Use this for
development environments or non-sensitive configuration data.

```ruby
require "secrets_vault"

# Create a new plaintext vault
vault = SecretsVault.new("my_app", adapter: :plaintext_file)

# Store configuration values
vault.store("LOG_LEVEL", "debug")
vault.store("FEATURE_FLAG_X", "enabled")

# Retrieve values
log_level = vault.fetch("LOG_LEVEL")
feature_flag = vault.fetch("FEATURE_FLAG_X")
```

### Custom Base Directory

By default, vaults are stored in `~/.config/secrets_vault/`. You can specify a
custom directory:

```ruby
vault = SecretsVault.new(
  "my_app",
  adapter: :encrypted_file,
  base_dir: "/path/to/custom/vault/directory"
)
```

### Error Handling

Secrets Vault raises specific exceptions for different error conditions:

```ruby
begin
  value = vault.fetch("NON_EXISTENT_KEY")
rescue SecretsVault::KeyError => e
  puts "Key not found: #{e.message}"
rescue SecretsVault::VaultNotFound => e
  puts "Vault doesn't exist: #{e.message}"
rescue SecretsVault::VaultCorrupted => e
  puts "Vault file is corrupted: #{e.message}"
rescue SecretsVault::EncryptionError => e
  puts "Encryption/decryption failed: #{e.message}"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/thoughtbot/secrets_vault.

## License

Open source templates are Copyright (c) thoughtbot, inc. It contains free
software that may be redistributed under the terms specified in the
[LICENSE](https://github.com/thoughtbot/planck/blob/main/LICENSE.txt)
file.

## Code of Conduct

Everyone interacting in the DataCustoms project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/thoughtbot/planck/blob/main/CODE_OF_CONDUCT.md).

<!-- START /templates/footer.md -->

## About thoughtbot

![thoughtbot](https://thoughtbot.com/thoughtbot-logo-for-readmes.svg)

This repo is maintained and funded by thoughtbot, inc. The names and logos for
thoughtbot are trademarks of thoughtbot, inc.

We love open source software! See [our other projects][community]. We are
[available for hire][hire].

[community]: https://thoughtbot.com/community?utm_source=github&utm_medium=readme&utm_campaign=planck
[hire]: https://thoughtbot.com/hire-us?utm_source=github&utm_medium=readme&utm_campaign=planck
