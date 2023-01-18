require 'sidekiq-rate-limiter/version'
require 'sidekiq-rate-limiter/fetch_patch'
require 'sidekiq/fetch'

Sidekiq.configure_server do |config|
  Sidekiq.options[:fetch] ||= Sidekiq::BasicFetch
  config.on(:startup) do
    Sidekiq.options[:fetch].prepend(Sidekiq::RateLimiter::FetchPatch)
  end
end
