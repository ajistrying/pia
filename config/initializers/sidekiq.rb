require 'sidekiq'

# Sidekiq configuration
Sidekiq.configure_server do |config|
  config.redis = { 
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    size: 10
  }
  
  # Server-specific configuration
  config.logger.level = Logger::INFO
end

Sidekiq.configure_client do |config|
  config.redis = { 
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    size: 5
  }
end

# Queue configuration with priorities
# Higher numbers = higher priority
Sidekiq.default_job_options = {
  'backtrace' => true,
  'retry' => 3
}

# Custom error handling
Sidekiq.configure_server do |config|
  config.death_handlers << ->(job, ex) do
    Rails.logger.error "Job #{job['class']} died: #{ex.message}"
    Rails.logger.error "Job arguments: #{job['args']}"
  end
end