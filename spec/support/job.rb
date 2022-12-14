require 'sidekiq'

class Job
  include Sidekiq::Worker
  sidekiq_options 'queue' => 'basic',
                  'retry' => false,
                  'rate'  => {
                      'limit'  => 1,
                      'period' => 1
                  }
  def perform(*args); end
end
