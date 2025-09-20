class SecretsVault
  module Encryption
    class Cipher
      attr_reader :iv

      def initialize
        @cipher = OpenSSL::Cipher.new("aes-256-gcm").encrypt
        @iv = @cipher.random_iv
      end

      def encrypt(plain_text, key:)
        @cipher.key = key
        ciphertext = @cipher.update(plain_text) + @cipher.final
        auth_tag = @cipher.auth_tag

        [ciphertext, auth_tag]
      end

      def key_len = @cipher.key_len
    end
  end
end
