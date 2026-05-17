# frozen_string_literal: true

# ActiveJob subclasses are only defined when ActiveJob is available.
# This keeps the gem usable in non-Rails contexts (eg specs without AJ).
if defined?(ActiveJob)
  module Ollama
    module Rails
      module Jobs
        # Pulls a model in the background — useful for first-boot provisioning.
        class PullModelJob < ActiveJob::Base
          queue_as :default

          def perform(model_name)
            Ollama::Rails.client.pull(model_name)
          end
        end

        # Generates embeddings for a batch of [id, text] pairs and yields back
        # via the configured block. Designed for bulk index seeding.
        class EmbedRecordsJob < ActiveJob::Base
          queue_as :default

          def perform(pairs, model:)
            client = Ollama::Rails.client
            pairs.map { |id, text| [id, client.embeddings.embed(model: model, input: text)] }
          end
        end
      end
    end
  end
end
