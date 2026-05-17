# frozen_string_literal: true

# Live integration: drive Rails-level helpers against a real Ollama daemon.
# Excluded by default; run with: INTEGRATION=1 bundle exec rspec spec/integration

RSpec.describe "Ollama::Rails live", :integration do
  before do
    reason = IntegrationHelper.skip_reason
    skip(reason) if reason
    Ollama::Rails.reset_config!
    Ollama::Rails.configure { |c| c.base_url = IntegrationHelper::OLLAMA_URL }
  end

  describe Ollama::Rails::Embeddable do
    before do
      reason = IntegrationHelper.skip_reason(requires_embed: true)
      skip(reason) if reason
    end

    it "writes a real embedding vector through the singleton client" do
      embed_model = IntegrationHelper.embed_model
      klass = Class.new do
        include Ollama::Rails::Embeddable
        attr_accessor :embedding, :body

        define_singleton_method(:name) { "DocumentInteg" }

        def initialize(body); @body = body; end
      end
      klass.embeddable attribute: :body, model: embed_model

      record = klass.new("hello world")
      record.run_ollama_embeddings_sync
      expect(record.embedding).to be_a(Array)
      expect(record.embedding.first).to be_a(Float)
    end
  end

  describe Ollama::Rails::TurboBroadcaster do
    before do
      reason = IntegrationHelper.skip_reason(requires_chat: true)
      skip(reason) if reason
    end

    it "broadcasts each streamed token from a real chat" do
      received = []
      channel = Object.new
      channel.define_singleton_method(:broadcast_append_to) do |stream, target:, content:|
        received << content
      end

      broadcaster = described_class.new(client: Ollama::Rails.client, channel: channel)
      broadcaster.stream(
        stream: "test", target: "msgs",
        model: IntegrationHelper.chat_model,
        messages: [{ role: "user", content: "Say ok" }]
      )
      expect(received).not_to be_empty
    end
  end
end
