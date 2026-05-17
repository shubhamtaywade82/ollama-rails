# frozen_string_literal: true

require "yaml"

module Ollama
  module Rails
    # Runtime configuration for the Rails integration.
    # Loaded automatically by the railtie from `config/ollama.yml` when present.
    class Configuration
      DEFAULT_BASE_URL = "http://localhost:11434"
      DEFAULT_MODEL = "llama3"

      attr_accessor :base_url, :default_model, :request_timeout, :logger

      def initialize(base_url: DEFAULT_BASE_URL, default_model: DEFAULT_MODEL, request_timeout: 60, logger: nil)
        @base_url = base_url
        @default_model = default_model
        @request_timeout = request_timeout
        @logger = logger
      end

      def self.load_file(path, env: "development")
        raw = YAML.safe_load_file(path, aliases: true) || {}
        section = raw[env.to_s].is_a?(Hash) ? raw[env.to_s] : raw
        new(
          base_url: section["base_url"] || section[:base_url] || DEFAULT_BASE_URL,
          default_model: section["default_model"] || section[:default_model] || DEFAULT_MODEL,
          request_timeout: section["request_timeout"] || section[:request_timeout] || 60
        )
      end
    end
  end
end
