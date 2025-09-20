require_relative "plaintext_file"
require_relative "../encryption"
require_relative "../tui"

class SecretsVault
  module Adapters
    class EncryptedFile < PlaintextFile
      def self.vault_filename_for(namespace) = "#{super(namespace)}.enc"

      def self.decode(contents)
        encrypted_payload = Encryption::EncryptedPayload.decode(contents)
        passphrase = TUI.ask("Enter vault password: ", echo: false)
        contents = Encryption.decrypt(encrypted_payload, passphrase)

        [JSON.parse(contents), passphrase]
      end

      def self.create(namespace, base_dir)
        puts "Creating vault #{namespace}."
        passphrase = TUI.ask("Enter vault password: ", echo: false, confirm: true)
        new(namespace, base_dir, {}, passphrase).tap(&:flush)
      rescue Error => e
        raise EncryptionError, e.message
      end

      def initialize(namespace, base_dir, values, passphrase)
        super(namespace, base_dir, values)
        @passphrase = passphrase
      end

      def encode  = encrypt.encode
      def encrypt = Encryption.encrypt(JSON.generate(@values), @passphrase)
    end
  end
end
