require_relative "helpers"

class SecretsVault
  module Adapters
    def self.find(name)
      Object.const_get("SecretsVault::Adapters::#{Helpers.pascal_case(name)}")
    rescue NameError
      raise Error, "Unknown adapter: #{name}"
    end
  end
end
