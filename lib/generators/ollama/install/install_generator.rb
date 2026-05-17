# frozen_string_literal: true

if defined?(::Rails::Generators::Base)
  module Ollama
    module Generators
      # `rails g ollama:install` — drops a default `config/ollama.yml` and
      # an initializer that lets the app override defaults at boot.
      class InstallGenerator < ::Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        def copy_config
          template "ollama.yml", "config/ollama.yml"
          template "initializer.rb", "config/initializers/ollama.rb"
        end
      end
    end
  end
end
