# frozen_string_literal: true

namespace :ollama do
  desc "Pull an Ollama model (defaults to Ollama::Rails.config.default_model)"
  task :pull, [:model] => :environment do |_t, args|
    model = args[:model] || Ollama::Rails.config.default_model
    Ollama::Rails.client.pull(model)
    puts "[ollama] pulled #{model}"
  end

  desc "List running Ollama models"
  task ps: :environment do
    Ollama::Rails.client.list_running.each do |m|
      puts "#{m["name"]}\t#{m["size_vram"]}"
    end
  end
end
