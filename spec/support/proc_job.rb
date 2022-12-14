require 'sidekiq'

class ProcJob
  include Sidekiq::Worker
  sidekiq_options 'queue' => 'basic',
                  'retry' => false,
                  'rate'  => {
                      'limit'  => ->(arg1, arg2) { arg2 },
                      'name'   => ->(arg1, arg2) { arg2 },
                      'period' => ->(arg1, arg2) { arg2 }
                  }
  def perform(arg1, arg2); end
end
