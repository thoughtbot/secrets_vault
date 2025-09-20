# frozen_string_literal: true

require_relative "secrets_vault/adapters"
require_relative "secrets_vault/adapters/plaintext_file"
require_relative "secrets_vault/adapters/encrypted_file"
require_relative "secrets_vault/version"
require "planck"
require "json"

class SecretsVault
  Error           = Class.new(StandardError)
  EncryptionError = Class.new(Error)
  VaultNotFound   = Class.new(Error)
  VaultCorrupted  = Class.new(Error)
  KeyError        = Class.new(Error)

  BASE_DIR = "~/.config/secrets_vault/"

  def initialize(namespace, adapter:, base_dir: BASE_DIR)
    @namespace = namespace
    @base_dir = File.expand_path(base_dir)
    @adapter = Adapters.find(adapter)
    @vault = nil
  end

  def fetch(key)
    find_vault.fetch(key)
  end

  def store(key, value)
    find_or_create_vault.store(key, value)
  end

  private

  def find_vault
    @vault ||= @adapter.find(@namespace, @base_dir)
  end

  def find_or_create_vault
    @vault ||= @adapter.find_or_create(@namespace, @base_dir)
  end
end
