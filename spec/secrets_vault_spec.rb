# frozen_string_literal: true

RSpec.describe SecretsVault do
  it "has a version number" do
    expect(SecretsVault::VERSION).not_to be nil
  end

  it "raises on unknown adapter" do
    expect { described_class.new("namespace", adapter: :foobar) }
      .to raise_error(SecretsVault::Error, /Unknown adapter: foobar/)
  end
end
