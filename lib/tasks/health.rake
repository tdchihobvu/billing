namespace :health do
  # Run nightly (e.g. Heroku Scheduler, daily at 02:00): bin/rails health:check_balances
  # Results appear on Administration -> System health -> Balance check.
  desc "Compare every invoice's stored balance with its receipts, for every company"
  task check_balances: :environment do
    Tenant.find_each do |tenant|
      run = BalanceCheckRun.create!(tenant: tenant)
      run.perform!
      puts "#{tenant.company_name}: #{run.invoices_checked} invoices checked, #{run.issues_found} need fixing (#{run.status})"
    end
  end
end
