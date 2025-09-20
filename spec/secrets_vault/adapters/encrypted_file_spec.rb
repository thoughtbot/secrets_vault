# frozen_string_literal: true

RSpec.describe SecretsVault::Adapters::EncryptedFile do
  context "when a vault file does not exist" do
    it "creates a new vault file and persists the key/value" do
      namespace = "myapp"
      vault_file = vault_file_path(namespace, encrypted: true)
      expect(File).not_to exist(vault_file)

      vault = SecretsVault.new(namespace, adapter: :encrypted_file)

      fill_in_password("s3cr3t!", confirm: true) do
        vault.store("API_KEY", "abc123")
      end

      expect(File).to exist(vault_file)
      header_json, ciphertext = File.readlines(vault_file)
      header = JSON.parse(header_json, symbolize_names: true)
      expect(header.keys).to match_array [:salt, :iterations, :iv, :auth_tag, :version, :kdf]
      expect(ciphertext).to be_a(String)
    end

    it "creates vault file in custom base_dir when specified" do
      custom_dir = File.join(Dir.pwd, "custom_vault_dir")
      namespace = "myapp"
      vault = SecretsVault.new(namespace, adapter: :encrypted_file, base_dir: custom_dir)

      fill_in_password("s3cr3t!", confirm: true) do
        vault.store("API_KEY", "abc123")
      end

      expect(Dir).to exist(custom_dir)
      vault_file = File.join(custom_dir, described_class.vault_filename_for(namespace))
      expect(File).to exist(vault_file)
      header_json, ciphertext = File.readlines(vault_file)
      header = JSON.parse(header_json, symbolize_names: true)
      expect(header.keys).to match_array [:salt, :iterations, :iv, :auth_tag, :version, :kdf]
      expect(ciphertext).to be_a(String)

      # Should not create file in current directory
      expect(File).not_to exist(described_class.vault_filename_for(namespace))
    end

    it "raises when password confirmation doesn't match" do
      namespace = "myapp"
      vault = SecretsVault.new(namespace, adapter: :encrypted_file)

      expect {
        fill_in_password("s3cr3t!\ndifferent\n") do
          vault.store("API_KEY", "abc123")
        end
      }.to raise_error(SecretsVault::EncryptionError, /Passphrase confirmation doesn't match/)

      vault_file = vault_file_path(namespace, encrypted: true)
      expect(File).not_to exist(vault_file)
    end
  end

  context "when a vault file already exists" do
    it "adds the new key/value to the existing vault" do
      namespace = "myapp"
      password = "s3cr3t!"
      fill_in_password(password, confirm: true) do
        create_encrypted_vault(namespace, contents: {"A" => 1, "B" => 2}, password:)
      end

      vault = SecretsVault.new(namespace, adapter: :encrypted_file)
      fill_in_password(password) do
        vault.store("A", 42)
      end

      vault = SecretsVault.new(namespace, adapter: :encrypted_file)
      fill_in_password(password) do
        expect(vault.fetch("A")).to eq(42)
        expect(vault.fetch("B")).to eq(2)
      end
    end

    it "raises when password is incorrect" do
      namespace = "myapp"
      password = "s3cr3t!"
      fill_in_password(password, confirm: true) do
        create_encrypted_vault(namespace, contents: {"A" => 1, "B" => 2}, password:)
      end

      vault = SecretsVault.new(namespace, adapter: :encrypted_file)
      expect {
        fill_in_password("wrong!") do
          vault.fetch("A")
        end
      }.to raise_error(SecretsVault::EncryptionError, /Decryption failed/)
    end
  end

  it "raises VaultNotFound when vault file does not exist" do
    namespace = "myapp"
    vault = SecretsVault.new(namespace, adapter: :encrypted_file)

    expect { vault.fetch("ANY") }
      .to raise_error(SecretsVault::VaultNotFound, /Vault not found: myapp/)
  end

  it "raises VaultCorrupted when header is invalid" do
    namespace = "myapp"
    vault_file = vault_file_path(namespace, encrypted: true)
    FileUtils.mkdir_p(File.dirname(vault_file))
    File.write(vault_file, "{ not: json }\nasdfasdf")
    vault = SecretsVault.new(namespace, adapter: :encrypted_file)

    expect { vault.fetch("ANY") }
      .to raise_error(SecretsVault::VaultCorrupted, /Vault is corrupted/)
  end

  it "raises VaultCorrupted when header missing" do
    namespace = "myapp"
    vault_file = vault_file_path(namespace, encrypted: true)
    FileUtils.mkdir_p(File.dirname(vault_file))
    File.write(vault_file, "\nasdfasdf")
    vault = SecretsVault.new(namespace, adapter: :encrypted_file)

    expect { vault.fetch("ANY") }
      .to raise_error(SecretsVault::VaultCorrupted, /Vault is corrupted/)
  end

  it "raises VaultCorrupted when ciphertext is missing" do
    namespace = "myapp"
    header = JSON.generate(salt: "00" * 16, iv: "00" * 12, auth_tag: "00" * 16, iterations: 1, version: 1, kdf: "pbkdf2")
    vault_file = vault_file_path(namespace, encrypted: true)
    FileUtils.mkdir_p(File.dirname(vault_file))
    File.write(vault_file, "#{header}]n")
    vault = SecretsVault.new(namespace, adapter: :encrypted_file)

    expect { vault.fetch("ANY") }
      .to raise_error(SecretsVault::VaultCorrupted, /Vault is corrupted/)
  end
end
