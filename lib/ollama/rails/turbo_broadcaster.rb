# frozen_string_literal: true

module Ollama
  module Rails
    # Stream Ollama chat tokens to a Turbo Streams target.
    #
    # Pass any object that responds to `broadcast_append_to(stream, target:, content:)`
    # (eg. `Turbo::StreamsChannel` in a Rails app, or a test double in specs).
    class TurboBroadcaster
      def initialize(client:, channel:)
        @client = client
        @channel = channel
      end

      def stream(stream:, target:, model:, messages:, options: {})
        hooks = {
          on_token: ->(text, _logprobs = nil) {
            @channel.broadcast_append_to(stream, target: target, content: text)
          },
          on_complete: ->(*) {}
        }
        @client.chat(model: model, messages: messages, options: options, hooks: hooks)
      end
    end
  end
end
