# frozen_string_literal: true

require "ollama_client"
require_relative "rails/version"
require_relative "rails/configuration"
require_relative "rails/turbo_broadcaster"
require_relative "rails/embeddable"
require_relative "rails/jobs"
require_relative "rails/railtie" if defined?(::Rails::Railtie)

module Ollama
  module Rails
    class Error < StandardError; end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield(config)
      end

      def reset_config!
        @config = nil
        @client = nil
      end

      def client
        @client ||= Ollama::Client.new(config: Ollama::Config.new.tap do |c|
          c.base_url = config.base_url
          c.timeout = config.request_timeout if c.respond_to?(:timeout=)
        end)
      end
    end
  end
end
