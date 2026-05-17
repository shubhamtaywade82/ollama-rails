# frozen_string_literal: true

namespace :ollama do
  desc "Pull an Ollama model by name (e.g., rake ollama:pull[llama3])"
  task :pull, [:model] => :environment do |_task, args|
    model_name = args[:model]
    if model_name.nil? || model_name.strip.empty?
      puts "ERROR: Model name is required. Usage: rake ollama:pull[llama3]"
      exit 1
    end

    puts "Pulling model #{model_name}..."
    Ollama::Rails.client.pull(model_name)
    puts "Successfully pulled #{model_name}."
  end

  desc "List currently running Ollama models"
  task ps: :environment do
    puts "Fetching running Ollama models..."
    models = Ollama::Rails.client.ps
    if models.empty?
      puts "No models currently running."
    else
      models.each do |m|
        puts "- #{m['name']} (Size: #{m['size']}, VRAM: #{m['size_vram']})"
      end
    end
  end

  desc "List all available Ollama models"
  task list: :environment do
    puts "Fetching available Ollama models..."
    models = Ollama::Rails.client.list_models
    if models.empty?
      puts "No models found."
    else
      models.each do |m|
        puts "- #{m['name']} (Details: #{m['details']&.fetch('parameter_size', 'N/A')})"
      end
    end
  end
end
