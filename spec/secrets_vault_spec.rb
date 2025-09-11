# frozen_string_literal: true

RSpec.describe SecretsVault do
  it "has a version number" do
    expect(SecretsVault::VERSION).not_to be nil
  end
end
