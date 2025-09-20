class SecretsVault
  module Helpers
    def self.pascal_case(name)
      name.to_s.split("_").map(&:capitalize).join
    end
  end
end
