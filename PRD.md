# Product Requirements Document: ollama-rails

## 1. Product Overview
**Name:** `ollama-rails`
**Role in Ecosystem:** The Ruby on Rails integration layer.
**Goal:** Provide zero-configuration, seamless integration of Ollama into Rails applications with out-of-the-box support for background jobs, websockets, and model binding.

## 2. Strategic Positioning
Sits on top of `ollama-client` (and optionally `ollama-stream` and `ollama-observability`). It ties the deterministic runtime into the Rails conventions, bridging the gap between infrastructure and web application paradigms.

## 3. System Requirements & Features
### 3.1. Core Rails Integrations
- **Railtie:** Automatic configuration loading from `config/ollama.yml` and integration with `Rails.logger`.
- **ActiveJob Helpers:** Pre-built background jobs for async model pulling, bulk embeddings generation, and offline inference.
- **ActionCable / Turbo Streams:** Helpers to directly broadcast `client.chat` streams to frontend clients using Hotwire/Turbo Streams.

### 3.2. Developer Ergonomics
- Rake tasks for managing local models (`rails ollama:pull`, `rails ollama:ps`).
- Model mixins/concerns (e.g., `Ollama::Embeddable`) to automatically sync Active Record models to vector structures.

## 4. Implementation Details
- **Dependencies:** `ollama-client`, `railties`, `activejob`, `actioncable`.
- **Generators:** Provide rails generators (`rails g ollama:install`) to scaffold configuration files and initializers.

## 5. Non-Goals
- Do not build a standalone Vector Database (recommend pgvector or similar).
- Do not implement custom UI components; provide the backend Turbo Stream hooks only.
