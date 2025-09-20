# frozen_string_literal: true

RSpec.describe SecretsVault::Encryption do
  subject { Class.new { extend SecretsVault::Encryption } }

  it "roundtrips correctly" do
    text = '{"GH_TOKEN":"token-123","msg":"hey"}'
    pass = "s3cret"

    enc = subject.encrypt(text, pass)
    out = subject.decrypt(enc, pass)

    expect(out).to eq(text)
  end

  describe "#encrypt" do
    it "produces different ciphertexts for same input (fresh salt/iv)" do
      text = "payload"
      pass = "secret"

      a = subject.encrypt(text, pass, iterations: 100)
      b = subject.encrypt(text, pass, iterations: 100)

      expect(a.header).not_to eq(b.header)
      expect(a.ciphertext).not_to eq(b.ciphertext)
    end

    it "includes required header fields" do
      enc = subject.encrypt("x", "p", iterations: 100)

      header = enc.header

      expect(header[:version]).to eq(1)
      expect(header[:kdf]).to eq("pbkdf2")
      expect(header.keys).to match_array [:salt, :iterations, :iv, :auth_tag, :version, :kdf]
      expect(Integer(header[:iterations])).to be > 0
    end

    it "rejects empty passphrase" do
      text = "x"

      expect { subject.encrypt(text, "", iterations: 100) }.to raise_error(ArgumentError)
    end

    it "does not mutate the input string" do
      text = "immutable"
      pass = "p"
      copy = text.dup

      subject.encrypt(text, pass, iterations: 100)

      expect(text).to eq(copy)
      expect(text.encoding).to eq(copy.encoding)
    end
  end

  describe "#decrypt" do
    it "fails with a wrong passphrase" do
      enc = subject.encrypt("x", "good", iterations: 100)

      expect { subject.decrypt(enc, "bad") }.to raise_error(SecretsVault::EncryptionError, /Decryption failed/i)
    end

    it "fails if header version is unsupported" do
      enc = subject.encrypt("x", "p", iterations: 100)
      bad_header = enc.header
      bad_header[:version] = 99
      tampered = SecretsVault::Encryption::EncryptedPayload.new(bad_header, enc.ciphertext)

      expect { subject.decrypt(tampered, "p") }
        .to raise_error(SecretsVault::EncryptionError, /Unsupported/)
    end

    it "fails if KDF is unsupported" do
      enc = subject.encrypt("x", "p", iterations: 100)
      bad_header = enc.header
      bad_header[:kdf] = "unknown"
      tampered = SecretsVault::Encryption::EncryptedPayload.new(bad_header, enc.ciphertext)

      expect { subject.decrypt(tampered, "p") }.to raise_error(SecretsVault::EncryptionError, /Unsupported/)
    end

    it "fails if tag is tampered (integrity check)" do
      enc = subject.encrypt("topsecret", "pass")
      header = enc.header
      header[:auth_tag][0] = "X"
      tampered = SecretsVault::Encryption::EncryptedPayload.new(header, enc.ciphertext)

      expect { subject.decrypt(tampered, "pass") }
        .to raise_error(SecretsVault::EncryptionError, /Decryption failed/i)
    end

    it "fails if IV is tampered" do
      enc = subject.encrypt("data", "pass", iterations: 100)
      header = enc.header
      header[:iv][0] = "X"
      tampered = SecretsVault::Encryption::EncryptedPayload.new(header, enc.ciphertext)

      expect { subject.decrypt(tampered, "pass") }
        .to raise_error(SecretsVault::EncryptionError, /Decryption failed/i)
    end

    it "fails if salt is tampered (wrong key derivation)" do
      enc = subject.encrypt("data", "pass", iterations: 100)
      header = enc.header
      header[:salt][0] = "X"
      tampered = SecretsVault::Encryption::EncryptedPayload.new(header, enc.ciphertext)

      expect { subject.decrypt(tampered, "pass") }
        .to raise_error(SecretsVault::EncryptionError, /Decryption failed/i)
    end

    it "rejects empty passphrase" do
      enc = subject.encrypt("x", "p", iterations: 100)

      expect { subject.decrypt(enc, "") }.to raise_error(ArgumentError)
    end

    it "supports binary plaintext" do
      bytes = (0..255).map(&:chr).join
      pass  = "p"

      enc = subject.encrypt(bytes, pass, iterations: 100)
      out = subject.decrypt(enc, pass)

      expect(out.bytes).to eq(bytes.bytes)
      expect(out.encoding).to eq(Encoding::BINARY)
    end
  end
end
