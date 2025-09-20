require "openssl"
require_relative "encryption/cipher"
require_relative "encryption/decipher"
require_relative "encryption/encrypted_payload"
require_relative "encryption/key_derivation"

class SecretsVault
  module Encryption
    extend self

    HEADER_VERSION = 1
    ITERATIONS     = 400_000

    def decrypt(encrypted_payload, passphrase)
      header = ensure_compatibility!(encrypted_payload.header)

      decipher = Decipher.new(iv: header[:iv], auth_tag: header[:auth_tag])
      key_derivation = KeyDerivation.new(
        passphrase,
        length: decipher.key_len,
        iterations: header[:iterations],
        salt: header[:salt]
      )
      ciphertext = encrypted_payload.ciphertext

      decipher.decrypt(ciphertext, key: key_derivation.key)
    rescue OpenSSL::Cipher::CipherError
      raise EncryptionError, "Decryption failed" # todo better error
    end

    def encrypt(plain_text, passphrase, iterations: ITERATIONS)
      cipher = Cipher.new
      key_derivation = KeyDerivation.new(passphrase, length: cipher.key_len, iterations: iterations)

      ciphertext, auth_tag = cipher.encrypt(plain_text, key: key_derivation.key)

      EncryptedPayload.new(
        header: {
          version: HEADER_VERSION,
          kdf: KeyDerivation::FUNCTION,
          iterations: iterations,
          salt: key_derivation.salt,
          iv: cipher.iv,
          auth_tag: auth_tag
        },
        ciphertext: ciphertext
      )
    end

    private

    def ensure_compatibility!(header)
      if header[:version] != HEADER_VERSION
        raise EncryptionError, "Unsupported header version #{header[:version]}"
      end

      if header[:kdf] != KeyDerivation::FUNCTION
        raise EncryptionError, "Unsupported KDF #{header[:kdf]}"
      end

      header
    end
  end
end
