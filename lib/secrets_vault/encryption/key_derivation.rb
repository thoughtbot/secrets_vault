class SecretsVault
  module Encryption
    class KeyDerivation
      FUNCTION = "pbkdf2"

      attr_reader :key, :salt

      def initialize(pass, length:, iterations:, salt: OpenSSL::Random.random_bytes(16))
        raise ArgumentError, "Passphrase is required" if pass.to_s.empty?

        @key = OpenSSL::KDF.pbkdf2_hmac(pass, salt:, iterations:, length:, hash: "SHA256")
        @salt = salt
      end
    end
  end
end
