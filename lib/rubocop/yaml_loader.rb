# frozen_string_literal: true

require 'yaml'

module RuboCop
  # This class provides a ruby version-agnostic entry-point for safe-loading
  # YAML configuration, falling back to unsafe loading where no safe-load
  # support is available.
  class YAMLLoader
    def self.safe_load(yaml_code, filename)
      if YAML.respond_to?(:safe_load) # Ruby 2.1+
        if defined?(SafeYAML) && SafeYAML.respond_to?(:load)
          SafeYAML.load(yaml_code, filename,
                        whitelisted_tags: %w[!ruby/regexp])
        else
          YAML.safe_load(yaml_code, [Regexp, Symbol], [], false, filename)
        end
      else
        YAML.load(yaml_code, filename) # rubocop:disable Security/YAMLLoad
      end
    end
  end
end
