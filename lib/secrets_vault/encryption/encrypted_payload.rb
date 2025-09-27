require "base64"

class SecretsVault
  module Encryption
    EncryptedPayload = Data.define(:header, :ciphertext) do
      def self.decode(string)
        header_json, b64_ciphertext = string.split("\n", 2)
        raise VaultCorrupted, "Vault is corrupted" if header_json.nil? || b64_ciphertext.nil?

        header = JSON.parse(header_json, symbolize_names: true)
        header[:iv]       = Base64.strict_decode64(header[:iv])
        header[:salt]     = Base64.strict_decode64(header[:salt])
        header[:auth_tag] = Base64.strict_decode64(header[:auth_tag])
        ciphertext        = Base64.strict_decode64(b64_ciphertext)

        new(header, ciphertext)
      rescue JSON::ParserError, ArgumentError
        raise VaultCorrupted, "Vault is corrupted"
      end

      def encode
        encoded_header = {
          version:    header[:version],
          kdf:        header[:kdf],
          iterations: header[:iterations],
          salt:       Base64.strict_encode64(header[:salt]),
          iv:         Base64.strict_encode64(header[:iv]),
          auth_tag:   Base64.strict_encode64(header[:auth_tag])
        }

        "#{JSON.generate(encoded_header)}\n#{Base64.strict_encode64(ciphertext)}"
      end
    end
  end
end
