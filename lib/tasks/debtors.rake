namespace :debtors do
  desc "TODO"
  task update_invoice_ageing: :environment do
    Invoice.unpaid.each do |invoice|
      puts("dealing with #{invoice.id}")
      invoice.update_debtors_age
    end
  end

  desc "TODO"
  task update_paid_invoices: :environment do
    License.active.where(paid: false).all.each do |license|
      puts("*** #{license.client_id}")
      begin
        c = Client.find(license.client_id)
        puts("********** #{license.validate_paid}")
      rescue ActiveRecord::RecordNotFound => e
        puts("client does not exist")
      end
    end
  end

  desc "TODO"
  task update_unpaid_invoices: :environment do
    as_at = Date.today
    invoices = Invoice.active.where(paid: true)
    i = 0
    invoices.each do |invoice|
      client = Client.find(invoice.client_id)
      unless client.nil?
        if client.credits_total_as_at(as_at).to_i < invoice.invoice_total.to_i
          puts("**** in #{i+=1} #{invoice.id} #{invoice.client_id}")
          invoice.update_attribute(:paid, false)
          invoice.update_attribute(:amount_paid, 0)
          invoice.license.update_attribute(:paid, false)
        end
      end
    end

    # licenses = License.where(paid: true)
    # i = 0
    # licenses.each do |license|
    #   client = Client.find(license.client_id)
    #   unless client.nil?
    #     if client.receipts.active.empty?
    #       puts("**** li #{i+=1} #{license.id} #{license.client_id}")
    #     end
    #   end
    # end
  end



end
