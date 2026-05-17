# frozen_string_literal: true

module Ollama
  module Rails
    # Mixin for Active Record models that should automatically maintain
    # an embedding for one of their text attributes.
    #
    #   class Document < ApplicationRecord
    #     include Ollama::Rails::Embeddable
    #     embeddable attribute: :body, model: "nomic-embed-text"
    #   end
    #
    # The host class must expose `#embedding=` and `#<attribute>` accessors.
    # In a real AR app this is wired through `before_save`; for non-AR usage
    # call `run_ollama_embeddings_sync` directly.
    module Embeddable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :ollama_embeddable_options

        def embeddable(attribute:, model:)
          @ollama_embeddable_options = { attribute: attribute, model: model }

          if respond_to?(:before_save)
            before_save :run_ollama_embeddings_sync
          end
        end
      end

      def run_ollama_embeddings_sync
        opts = self.class.ollama_embeddable_options or return
        text = send(opts[:attribute])
        return if text.to_s.empty?

        vector = Ollama::Rails.client.embeddings.embed(model: opts[:model], input: text)
        self.embedding = vector
      end
    end
  end
end
