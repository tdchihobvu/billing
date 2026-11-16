# Runs a balance check in the background (it reads every invoice, about a minute).
class BalanceCheckJob < ApplicationJob
  queue_as :default

  def perform(run_id)
    run = BalanceCheckRun.find_by(id: run_id)
    run&.perform! if run&.running?
  end
end
