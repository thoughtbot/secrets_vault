# frozen_string_literal: true

RSpec.describe SecretsVault::Adapters::PlaintextFile do
  describe "#store" do
    context "when a vault file does not exist" do
      it "creates a new vault file and persists the key/value" do
        namespace = "myapp"
        vault = SecretsVault.new(namespace, adapter: :plaintext_file)

        vault.store("API_KEY", "abc123")

        vault_file = vault_file_path(namespace)
        expect(File).to exist(vault_file)
        json = JSON.parse(File.read(vault_file))
        expect(json).to eq({"API_KEY" => "abc123"})
      end

      it "creates vault file in custom base_dir when specified" do
        custom_dir = File.join(Dir.pwd, "custom_vault_dir")
        namespace = "myapp"
        vault = SecretsVault.new(namespace, adapter: :plaintext_file, base_dir: custom_dir)

        vault.store("API_KEY", "abc123")

        expect(Dir).to exist(custom_dir)
        vault_file = File.join(custom_dir, ".#{namespace}.json")
        expect(File).to exist(vault_file)
        json = JSON.parse(File.read(vault_file))
        expect(json).to eq({"API_KEY" => "abc123"})
      end

      it "creates nested directories when base_dir has multiple levels" do
        custom_dir = File.join(Dir.pwd, "level1", "level2", "vaults")
        namespace = "myapp"
        vault = SecretsVault.new(namespace, adapter: :plaintext_file, base_dir: custom_dir)

        vault.store("API_KEY", "abc123")

        expect(Dir).to exist(custom_dir)
        vault_file = File.join(custom_dir, ".#{namespace}.json")
        expect(File).to exist(vault_file)
        json = JSON.parse(File.read(vault_file))
        expect(json).to eq({"API_KEY" => "abc123"})
      end
    end

    context "when a vault file already exists" do
      it "adds the new key/value to the existing vault" do
        namespace = "myapp"
        vault_file = create_vault(namespace, {"A" => 1, "B" => 2})
        vault = SecretsVault.new(namespace, adapter: :plaintext_file)

        vault.store("A", 42)

        json = JSON.parse(File.read(vault_file))
        expect(json).to eq({"A" => 42, "B" => 2})
      end

      it "handles existing vault in custom base_dir" do
        custom_dir = File.join(Dir.pwd, "custom_vault_dir")
        FileUtils.mkdir_p(custom_dir)
        namespace = "myapp"
        vault_file = create_vault(namespace, {"A" => 1, "B" => 2}, base_dir: custom_dir)
        vault = SecretsVault.new(namespace, adapter: :plaintext_file, base_dir: custom_dir)

        vault.store("A", 42)

        json = JSON.parse(File.read(vault_file))
        expect(json).to eq({"A" => 42, "B" => 2})
      end
    end
  end

  describe "#fetch" do
    it "returns the stored value for a key" do
      namespace = "myapp"
      create_vault(namespace, {"X" => "y"})
      vault = SecretsVault.new(namespace, adapter: :plaintext_file)

      value = vault.fetch("X")

      expect(value).to eq("y")
    end

    it "fetches from vault in custom base_dir" do
      custom_dir = File.join(Dir.pwd, "custom_vault_dir")
      FileUtils.mkdir_p(custom_dir)
      namespace = "myapp"
      create_vault(namespace, {"X" => "y"}, base_dir: custom_dir)
      vault = SecretsVault.new(namespace, adapter: :plaintext_file, base_dir: custom_dir)

      value = vault.fetch("X")

      expect(value).to eq("y")
    end

    it "raises KeyError when key is missing" do
      namespace = "myapp"
      create_vault(namespace, {})
      vault = SecretsVault.new(namespace, adapter: :plaintext_file)

      expect { vault.fetch("MISSING") }
        .to raise_error(SecretsVault::KeyError, /Key not found: MISSING/)
    end

    it "raises VaultNotFound when vault file does not exist" do
      namespace = "myapp"
      vault = SecretsVault.new(namespace, adapter: :plaintext_file)

      expect { vault.fetch("ANY") }
        .to raise_error(SecretsVault::VaultNotFound, /Vault not found: myapp/)
    end

    it "raises VaultCorrupted when JSON is invalid" do
      namespace = "myapp"
      vault_file = vault_file_path(namespace)
      FileUtils.mkdir_p(File.dirname(vault_file))
      File.write(vault_file, "{ not: json }")
      vault = SecretsVault.new(namespace, adapter: :plaintext_file)

      expect { vault.fetch("ANY") }
        .to raise_error(SecretsVault::VaultCorrupted, /Vault is corrupted/)
    end
  end

  describe "security hardening" do
    it "sanitizes namespace to prevent path traversal and illegal chars" do
      namespace = "../../etc/passwd..//..:evil"
      vault = SecretsVault.new(namespace, adapter: :plaintext_file)
      vault.store("K", "V")

      expect(File).to exist(vault_file_path("etc_passwd_evil"))
    end

    it "sets restrictive permissions on directory and file" do
      namespace = "myapp"
      vault = SecretsVault.new(namespace, adapter: :plaintext_file)
      vault.store("API_KEY", "abc123")

      dir = File.expand_path(SecretsVault::BASE_DIR)
      file = vault_file_path(namespace)

      dir_mode  = File.stat(dir).mode & 0o777
      file_mode = File.stat(file).mode & 0o777

      expect(dir_mode).to satisfy { |m| [0o700, 0o600].include?(m) || m == 0 } # some FS may mask
      expect(file_mode).to eq(0o600)
    end
  end
end
