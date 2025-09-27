class SecretsVault
  module Helpers
    def self.pascal_case(name)
      name.to_s.split("_").map(&:capitalize).join
    end

    # Ensure the component is safe for filenames to avoid path traversal and illegal chars
    def self.sanitize_path_component(component)
      sanitized = component.to_s.gsub(/[^A-Za-z0-9_-]/, "_")
      sanitized = sanitized.gsub(/_+/, "_")
      sanitized = sanitized.delete_prefix("_").delete_suffix("_")
      sanitized = "default" if sanitized.empty?
      sanitized
    end

    def self.ensure_dir_exists(path)
      File.expand_path(path).tap do |dir|
        FileUtils.mkdir_p(dir, mode: 0o700)
        File.chmod(0o700, dir) rescue nil
      end
    end
  end
end
