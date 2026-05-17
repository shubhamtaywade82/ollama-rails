# frozen_string_literal: true

require "tempfile"
require "yaml"

RSpec.describe Ollama::Rails do
  it "has a version number" do
    expect(Ollama::Rails::VERSION).not_to be nil
  end

  describe Ollama::Rails::Configuration do
    it "exposes default base_url and default_model" do
      cfg = described_class.new
      expect(cfg.base_url).to eq("http://localhost:11434")
      expect(cfg.default_model).to eq("llama3")
    end

    it "loads from a YAML file with environment section" do
      Tempfile.create(["ollama", ".yml"]) do |f|
        f.write({ "test" => { "base_url" => "http://gpu.example:11434", "default_model" => "qwen2" } }.to_yaml)
        f.flush
        cfg = described_class.load_file(f.path, env: "test")
        expect(cfg.base_url).to eq("http://gpu.example:11434")
        expect(cfg.default_model).to eq("qwen2")
      end
    end

    it "falls back to top-level keys when env section is absent" do
      Tempfile.create(["ollama", ".yml"]) do |f|
        f.write({ "base_url" => "http://flat:11434" }.to_yaml)
        f.flush
        cfg = described_class.load_file(f.path, env: "production")
        expect(cfg.base_url).to eq("http://flat:11434")
      end
    end
  end

  describe Ollama::Rails do
    it "exposes a singleton .config" do
      expect(described_class.config).to be_a(Ollama::Rails::Configuration)
    end

    it "yields config to .configure block" do
      described_class.configure do |c|
        c.default_model = "phi3"
      end
      expect(described_class.config.default_model).to eq("phi3")
    ensure
      described_class.reset_config!
    end

    it "lazily builds a default Ollama client from config" do
      described_class.reset_config!
      client = described_class.client
      expect(client).to be_a(Ollama::Client)
    end
  end

  describe Ollama::Rails::TurboBroadcaster do
    it "broadcasts each streamed token to the given target via the channel" do
      broadcasts = []
      channel = Class.new do
        define_method(:broadcast_append_to) do |stream, target:, content:|
          broadcasts << { stream: stream, target: target, content: content }
        end
      end.new

      ollama = instance_double(Ollama::Client)
      allow(ollama).to receive(:chat) do |args|
        args[:hooks][:on_token].call("Hello", nil)
        args[:hooks][:on_token].call(" world", nil)
        args[:hooks][:on_complete].call
      end

      broadcaster = described_class.new(client: ollama, channel: channel)
      broadcaster.stream(
        stream: "chat_42",
        target: "messages",
        model: "llama3",
        messages: [{ role: "user", content: "hi" }]
      )

      expect(broadcasts.map { |b| b[:content] }).to eq(["Hello", " world"])
      expect(broadcasts.first[:stream]).to eq("chat_42")
      expect(broadcasts.first[:target]).to eq("messages")
    end
  end

  describe Ollama::Rails::Embeddable do
    let(:model_class) do
      Class.new do
        include Ollama::Rails::Embeddable
        attr_accessor :embedding, :body

        def initialize(body)
          @body = body
        end

        embeddable attribute: :body, model: "nomic-embed-text"

        # mimic AR save callback hook surface
        def save
          run_ollama_embeddings_sync
          true
        end
      end
    end

    it "fills #embedding by calling the Ollama embeddings API on save" do
      ollama = instance_double(Ollama::Client)
      embeds = instance_double("Ollama::Embeddings")
      allow(Ollama::Rails).to receive(:client).and_return(ollama)
      allow(ollama).to receive(:embeddings).and_return(embeds)
      expect(embeds).to receive(:embed).with(model: "nomic-embed-text", input: "the body text").and_return([0.1, 0.2])

      record = model_class.new("the body text")
      record.save
      expect(record.embedding).to eq([0.1, 0.2])
    end
  end

  describe Ollama::Rails::Jobs do
    let(:ollama) { instance_double(Ollama::Client) }

    before do
      allow(Ollama::Rails).to receive(:client).and_return(ollama)
    end

    describe Ollama::Rails::Jobs::PullModelJob do
      it "pulls the requested model via Ollama client" do
        expect(ollama).to receive(:pull).with("llama3")
        described_class.new.perform("llama3")
      end
    end

    describe Ollama::Rails::Jobs::EmbedRecordsJob do
      it "embeds a batch of records and returns pairs of [id, embedding]" do
        embeds = instance_double("Ollama::Embeddings")
        allow(ollama).to receive(:embeddings).and_return(embeds)
        expect(embeds).to receive(:embed).with(model: "nomic-embed-text", input: "text1").and_return([0.1, 0.2])
        expect(embeds).to receive(:embed).with(model: "nomic-embed-text", input: "text2").and_return([0.3, 0.4])

        res = described_class.new.perform([[1, "text1"], [2, "text2"]], model: "nomic-embed-text")
        expect(res).to eq([[1, [0.1, 0.2]], [2, [0.3, 0.4]]])
      end
    end
  end

  describe "ollama.rake tasks" do
    let(:ollama) { instance_double(Ollama::Client) }

    before(:all) do
      Rake.application.rake_require("tasks/ollama", [File.expand_path("../../lib", __dir__)])
      Rake::Task.define_task(:environment)
    end

    before do
      allow(Ollama::Rails).to receive(:client).and_return(ollama)
    end

    it "pulls a model with rake ollama:pull" do
      expect(ollama).to receive(:pull).with("qwen2")
      expect { Rake::Task["ollama:pull"].invoke("qwen2") }.to output(/Pulling model qwen2/).to_stdout
    ensure
      Rake::Task["ollama:pull"].reenable
    end

    it "lists running models with rake ollama:ps" do
      allow(ollama).to receive(:ps).and_return([{ "name" => "llama3", "size" => 123, "size_vram" => 456 }])
      expect { Rake::Task["ollama:ps"].invoke }.to output(/llama3/).to_stdout
    ensure
      Rake::Task["ollama:ps"].reenable
    end

    it "lists available models with rake ollama:list" do
      allow(ollama).to receive(:list_models).and_return([{ "name" => "llama3", "details" => { "parameter_size" => "8B" } }])
      expect { Rake::Task["ollama:list"].invoke }.to output(/llama3/).to_stdout
    ensure
      Rake::Task["ollama:list"].reenable
    end
  end
end
