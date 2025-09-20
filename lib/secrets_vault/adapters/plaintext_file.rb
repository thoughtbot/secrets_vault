require "fileutils"

class SecretsVault
  module Adapters
    class PlaintextFile
      def self.vault_filename_for(namespace) = ".#{namespace}.json"

      def self.find_or_create(namespace, base_dir)
        find(namespace, base_dir)
      rescue VaultNotFound
        create(namespace, base_dir)
      end

      def self.find(namespace, base_dir)
        vault_path = File.join(base_dir, vault_filename_for(namespace))
        File.read(vault_path)
          .then { |contents| decode(contents) }
          .then { |args| new(namespace, base_dir, *args) }
      rescue Errno::ENOENT
        raise VaultNotFound, "Vault not found: #{namespace}"
      rescue JSON::ParserError
        raise VaultCorrupted, "Vault is corrupted"
      end

      def self.decode(contents) = [JSON.parse(contents)]

      def self.create(namespace, base_dir)
        new(namespace, base_dir, {}).tap(&:flush)
      end

      def initialize(namespace, base_dir, values)
        @base_dir = File.expand_path(base_dir)
        FileUtils.mkdir_p(@base_dir)
        @path = File.join(@base_dir, self.class.vault_filename_for(namespace))
        @values = values
      end

      def fetch(key)
        @values.fetch(key) { raise KeyError, "Key not found: #{key}" }
      end

      def store(key, value)
        @values[key] = value
        flush
      end

      def flush = Planck.atomic_write(@path, encode)
      def encode = JSON.generate(@values)
    end
  end
end
