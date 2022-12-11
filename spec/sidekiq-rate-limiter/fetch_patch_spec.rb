require 'spec_helper'
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/fetch'
require 'support/job'
require 'support/proc_job'

RSpec.describe Sidekiq::RateLimiter::FetchPatch do
  let(:options)       { { queues: [queue, another_queue, another_queue] } }
  let(:queue)         { 'basic' }
  let(:another_queue) { 'some_other_queue' }
  let(:args)          { ['I am some args'] }
  let(:worker)        { Job }
  let(:proc_worker)   { ProcJob }
  let(:redis_class)   { Sidekiq.redis { |conn| conn.class } }
  let(:patched_class) { Class.new(Sidekiq::BasicFetch) { prepend Sidekiq::RateLimiter::FetchPatch } }

  it 'should retrieve work with strict setting' do
    timeout =
      if defined? patched_class::TIMEOUT
        patched_class::TIMEOUT
      else
        Sidekiq::Fetcher::TIMEOUT
      end

    fetch = patched_class.new options.merge(:strict => true)
    expect(fetch.queues_cmd).to eql(["queue:#{queue}", "queue:#{another_queue}", timeout])
  end

  it 'should retrieve work', queuing: true do
    worker.perform_async(*args)
    fetch   = patched_class.new(options)
    work    = fetch.retrieve_work
    parsed  = JSON.parse(work.respond_to?(:message) ? work.message : work.job)

    expect(work).not_to be_nil
    expect(work.queue_name).to eql(queue)
    expect(work.acknowledge).to be_nil

    expect(parsed).to include(worker.get_sidekiq_options)
    expect(parsed).to include("class" => worker.to_s, "args" => args)
    expect(parsed).to include("jid", "enqueued_at")

    q = Sidekiq::Queue.new(queue)
    expect(q.size).to eq 0
  end

  it 'should place rate-limited work at the back of the queue', queuing: true do
    worker.perform_async(*args)
    expect_any_instance_of(Sidekiq::RateLimiter::Limit).to receive(:exceeded?).and_return(true)
    expect_any_instance_of(redis_class).to receive(:lpush).exactly(:once).and_call_original

    fetch = patched_class.new(options)
    expect(fetch.retrieve_work).to be_nil

    q = Sidekiq::Queue.new(queue)
    expect(q.size).to eq 1
  end

  it 'should accept procs for limit, name, and period config keys', queuing: true do
    proc_worker.perform_async(1,2)

    expect(Sidekiq::RateLimiter::Limit).
      to receive(:new).
      with(anything(), {:limit => 2, :interval => 2, :name => "2"}).
      and_call_original

    fetch = patched_class.new(options)
    work  = fetch.retrieve_work
  end

end
