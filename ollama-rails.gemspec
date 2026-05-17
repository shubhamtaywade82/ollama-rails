# frozen_string_literal: true

require_relative "lib/ollama/rails/version"

Gem::Specification.new do |spec|
  spec.name = "ollama-rails"
  spec.version = Ollama::Rails::VERSION
  spec.authors = ["Shubham Taywade"]
  spec.email = ["shubhamtaywade82@gmail.com"]

  spec.summary = "Rails integration layer for Ollama."
  spec.description = "Railtie, ActiveJob helpers, ActionCable/Turbo Streams broadcasters, generators, and rake tasks for using Ollama in Ruby on Rails apps."
  spec.homepage = "https://github.com/ollama-rb/ollama-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ollama-rb/ollama-rails"
  spec.metadata["changelog_uri"] = "https://github.com/ollama-rb/ollama-rails/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ollama-client", "~> 1.3"
  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "activejob", ">= 7.0"
end
