class HealthCheckJob < ApplicationJob
  queue_as :default
  
  def perform(message = "Sidekiq is working!")
    Rails.logger.info "HealthCheckJob executed: #{message}"
    puts "HealthCheckJob executed at #{Time.current}: #{message}"
  end
end