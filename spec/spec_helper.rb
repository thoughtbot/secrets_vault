# frozen_string_literal: true

require "simplecov"

if ENV["COVERAGE"]
  SimpleCov.start do
    enable_coverage :branch
    add_filter "/spec/"
  end
end

require "secrets_vault"
require "tmpdir"
require "fileutils"

module TestHelpers
  def create_vault(namespace, contents, base_dir: SecretsVault::BASE_DIR)
    vault_file_path(namespace, base_dir: base_dir).tap do |path|
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.generate(contents))
    end
  end

  def vault_file_path(namespace, base_dir: SecretsVault::BASE_DIR, encrypted: false)
    base_dir = File.expand_path(base_dir)
    adapter_class = encrypted ? SecretsVault::Adapters::EncryptedFile : SecretsVault::Adapters::PlaintextFile

    File.join(base_dir, adapter_class.vault_filename_for(namespace))
  end

  def create_encrypted_vault(namespace, contents:, password:)
    with_stdin("#{password}\n#{password}\n") do
      base_dir = File.expand_path(SecretsVault::BASE_DIR)
      SecretsVault::Adapters::EncryptedFile.create(namespace, base_dir).tap do |vault|
        contents.each { |k, v| vault.store(k, v) }
      end
    end
  end

  def fill_in_password(password, confirm: false, &)
    stdin = confirm ? "#{password}\n#{password}\n" : "#{password}\n"
    stdout = confirm ? /Enter vault password: \n\(confirm\) Enter vault password: \n/ : /Enter vault password: \n/

    expect {
      with_stdin(stdin, &)
    }.to output(stdout).to_stdout
  end

  def with_stdin(stdin)
    require "stringio"

    original_stdin = $stdin
    input = StringIO.new(stdin)
    def input.noecho = yield self # StringIO does not implement noecho

    $stdin = input
    yield
  ensure
    $stdin = original_stdin
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        example.run

        # Clean up test files from default directory after each test
        base_dir = File.expand_path(SecretsVault::BASE_DIR)
        if Dir.exist?(base_dir)
          # Clean up vault files (they start with a dot)
          Dir.glob(File.join(base_dir, ".*")).each do |file|
            next if ['.', '..'].include?(File.basename(file))
            File.delete(file) if File.file?(file)
          end
          Dir.rmdir(base_dir) if Dir.empty?(base_dir)
        end
      end
    end
  end

  config.include TestHelpers
end
