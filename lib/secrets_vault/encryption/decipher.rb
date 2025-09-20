class SecretsVault
  module Encryption
    class Decipher
      def initialize(iv:, auth_tag:)
        @decipher = OpenSSL::Cipher.new("aes-256-gcm").decrypt
        @decipher.iv = iv
        @decipher.auth_tag = auth_tag
      end

      def decrypt(ciphertext, key:)
        @decipher.key = key

        @decipher.update(ciphertext) + @decipher.final
      end

      def key_len = @decipher.key_len
    end
  end
end
