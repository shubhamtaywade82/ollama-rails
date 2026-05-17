# frozen_string_literal: true

if defined?(Rails::Railtie)
  module Ollama
    module Rails
      # Loads `config/ollama.yml` (if present), wires Rails.logger into the
      # Ollama config, and exposes rake tasks defined in `tasks/ollama.rake`.
      class Railtie < ::Rails::Railtie
        config.ollama = ActiveSupport::OrderedOptions.new if defined?(ActiveSupport::OrderedOptions)

        initializer "ollama.load_config" do |app|
          yml = app.root.join("config", "ollama.yml")
          if yml.exist?
            Ollama::Rails.instance_variable_set(:@config, Configuration.load_file(yml.to_s, env: ::Rails.env))
          end
          Ollama::Rails.config.logger ||= ::Rails.logger
        end

        rake_tasks do
          path = File.expand_path("../../tasks/ollama.rake", __dir__)
          load(path) if File.exist?(path)
        end
      end
    end
  end
end
