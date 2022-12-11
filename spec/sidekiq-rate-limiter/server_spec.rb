require 'spec_helper'
require 'sidekiq/util'
require 'support/job'

RSpec.describe Sidekiq::RateLimiter, 'server configuration' do
  before do
    allow(Sidekiq).to receive(:server?).and_return true
    require 'sidekiq-rate-limiter/server'
  end

  it 'should set Sidekiq.options[:fetch] to Sidekiq::BasicFetch if blank' do
    Sidekiq.configure_server do |config|
      expect(Sidekiq.options[:fetch]).to eql(Sidekiq::BasicFetch)
    end
  end

  it 'should patch the retrieve_work method' do
    Class.new.extend(Sidekiq::Util).fire_event(:startup)
    Job.perform_async([])
    patched_fetch_class = nil
    Sidekiq.configure_server do |config|
      patched_fetch_class = Sidekiq.options[:fetch]
    end
    expect(Sidekiq::RateLimiter).to receive(:limit)
    patched_fetch_class.new(queues: [:basic]).retrieve_work
  end
end
