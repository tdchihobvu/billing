namespace :mytest do

  task refresh: :environment do
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
  task random_number: :environment do
    puts SecureRandom.random_number(1000..10000)
  end

  task update_invoice_age: :environment do
    invoice = Invoice.find(59)
    puts("dealing with #{invoice.id}")
    invoice.update_debtors_age
  end

  task reset_statement: :environment do
    client = Client.find(83)
    client.reset_statement
  end

  task populate_account_numbers: :environment do   
    # check if accounts without account numbers exists
    unless Client.all.empty?
      Client.all.each do |client|
        puts("*** #{client.name} with #{client.client_account_number}")
        acc_no = 10000 + client.id.to_i
        client.update_attribute(:client_account_number, acc_no)
      end
    end
  end

  task update_users: :environment do   
    User.where(tenant_id: 3).all.each do |u|
      u.update_attribute(:password, "#{u.username}123")
    end
  end

  task remove_invoice_items: :environment do   
    InvoiceItem.all.each do |i|
      if i.invoice.nil?
        puts("destroying #{i.id} with #{i.invoice_id}")
        i.destroy
      end
    end
    Receipt.all.each do |r|
      if r.client.nil?
        puts("destroying #{r.id} with #{r.client_id}")
        r.destroy
      end
    end
    Invoice.all.each do |n|
      if n.client.nil?
        puts("destroying #{n.id} with #{n.client_id}")
        n.destroy
      end
    end
    Transaction.all.each do |n|
      if n.client.nil?
        puts("destroying #{n.id} with #{n.client_id}")
        n.destroy
      end
    end
  end

  task update_source_reference_numbers: :environment do   
    User.where(tenant_id: 3).all.each do |u|
      u.update_attribute(:password, "#{u.username}123")
    end
  end

  task fix_wrong_user_invoices: :environment do   
    user = User.find(9)
    device = Device.find_by(user_id: user.id)
    clients = Client.where(terminal_id: device.terminal_id)
    invoices = Invoice.where(user_id: user.id)
    x = 0
    puts("#,Invoice,Current User,Actual User")
    invoices.each do |invoice|
      real_device = Device.find_by(terminal_id: invoice.client.terminal_id)
      unless real_device.nil?
        if invoice.user_id != User.find(real_device.user_id).id
          puts("#{x+=1},#{invoice.invoice_number},#{invoice.user_id},#{User.find(real_device.user_id).id}")
          invoice.update_attribute(:user_id, User.find(real_device.user_id).id)
          invoice.update_attribute(:device_id, real_device.id)
          invoice.update_attribute(:user_fullname, User.find(real_device.user_id).fullname)
          # get the receipts with the reference
        end
      end
    end
  end

  task remove_license_without_invoices: :environment do   
    licenses = License.find_by_sql("SELECT *
                                    FROM licenses l
                                    WHERE NOT EXISTS (
                                        SELECT 1
                                        FROM invoices i
                                        WHERE i.id = l.invoice_id
                                    ); ")
    licenses.each_with_index do |license|
      puts("*** #{license.id} - #{license.renewal_date}")
      license.destroy
    end
  end  

  task invoices_without_licenses: :environment do   
    invoices = Invoice.find_by_sql("SELECT *
                                    FROM invoices i
                                    WHERE NOT EXISTS (
                                        SELECT 1
                                        FROM licenses l
                                        WHERE i.id = l.invoice_id
                                    ); ")
    invoices.each_with_index do |invoice|
      puts("*** #{invoice.id} - #{invoice.invoice_date}")
    end
  end 

  task get_invoice_duplicates: :environment do 
    # find the duplicates
    @duplicate_invoices = Invoice.select(:invoice_date, :client_id)
       .group(:invoice_date, :client_id)
       .having('COUNT(*) > 1')
       .count

    # clean the duplicates
    @duplicate_invoices = Invoice.select(:invoice_date, :invoice_number, :amount, :client_id)
      .group(:invoice_date, :invoice_number, :amount, :client_id)
      .having('COUNT(*) > 1').each do |dup|
      duplicates = Invoice.where(
          invoice_date: dup.invoice_date,
          invoice_number: dup.invoice_number,
          amount: dup.amount,
          client_id: dup.client_id
        )
        # Keep the first record, delete the rest
        duplicates.offset(1).destroy_all
      end

      # update the loop
      Invoice.where(user_fullname: nil).find_each do |invoice|
        next if invoice.user_id.nil?
        invoice.update!(user_fullname: invoice.user.user_fullname)
      end


  end

  task remove_user_data: :environment do
    terminal_id = 6375
    user = User.find_by(username: 'aibes')
    device = Device.find_by(terminal_id: terminal_id)
    Client.where(terminal_id: terminal_id).delete_all
    Invoice.where(device_id: device.id).delete_all
    Invoice.where(user_id: user.id).delete_all
    Receipt.where(device_id: device.id).delete_all
    Receipt.where(user_id: user.id).delete_all
    licenses = License.find_by_sql("SELECT * FROM licenses l WHERE NOT EXISTS (SELECT 1 FROM invoices i WHERE i.id = l.invoice_id);")
    licenses.each_with_index do |license|
      puts("*** #{license.id} - #{license.renewal_date}")
      license.destroy
    end
  end 

  task invoices_without_clients: :environment do   
    invoices = Invoice.find_by_sql("SELECT *
                                    FROM invoices i
                                    WHERE NOT EXISTS (
                                        SELECT 1
                                        FROM clients c
                                        WHERE c.id = i.client_id
                                    ); ")
    invoices.each_with_index do |invoice|
      puts("*** #{invoice.id} - #{invoice.invoice_date}")
    end
  end

  task populate_clients: :environment do  
    current_user = User.find(1)
    current_user.tenant.clients.order('name Asc').each do |client|
      puts("*** #{client.name}")
    end
  end

  task update_invoice_exchange_rates: :environment do 
    invoices = Invoice.active.where("rate <= 0")
    current_user = User.find_by(username: 'david')
    tenant = current_user.tenant
    # get exchange rate frequency
    config = ConfigKey.find_by(name: 'Exchange Rate Update Frequency')
    return nil unless config

    setting = tenant.system_settings.find_by(config_key_id: config.id)
    exchange_rate_update_frequency = setting&.config_value

    invoices.each do |inv|
      transaction_date = inv.invoice_date 
      puts("#{inv.client.name}*** invoice #{inv.id} #{inv.invoice_date} - #{inv.rate} - #{inv.converted_rate}")
      unless ExchangeRate.active_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency).nil?
        inv.update(rate: ExchangeRate.active_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency), converted_rate: 1/ExchangeRate.active_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency))
      else
        inv.update(rate: 1, converted_rate: 1)
      end
    end
  end

  task update_client_statements: :environment do
    @clients = Client.all 
    # @clients = Client.where(id: 1975) 
    as_at = Date.today
    # target_currency = Currency.find_by(name: 'ZWL')
    @clients.each do |client|
      tenant = client.tenant
      client.reset_statement
      client.update_statement(tenant)
      # puts("*** dealing with #{client.id} #{client.name} - DR #{client.debits_total_as_at(as_at,target_currency)}")
      # puts("*** dealing with #{client.id} #{client.name} - CR #{client.credits_total_as_at(as_at,target_currency)}")
      # puts("*** dealing with #{client.id} #{client.name} - BAL #{client.account_balance_as_at(as_at,target_currency)}")
      # client.invoices.each do |invoice|
      #   puts(">>>>>>> #{invoice.client.name} - #{invoice.rated_invoice_total(target_currency)}")
      # end
    end
  end 

  task get_clients_with_mixed_currencies: :environment do
    @clients = Client.all  
    @clients.each do |client|
      tenant = client.tenant
      client.reset_statement
      client.update_statement(tenant)
      puts("*** dealing with #{client.id} #{client.name}")
    end
  end 

  task test_invoice: :environment do
    @invoice = Invoice.find(2257)
    @currency = @invoice.client.currency
    puts @invoice.invoice_vat(@currency)
  end

  task test_client_statement: :environment do
    @client = Client.find(823)
    # @target_currency = @client.currency
    # @client.transactions.order(transaction_date: :asc, debit: :desc).where("id = 4812 AND deleted = false").order('transaction_date Asc').map do |transaction|
    #   puts transaction.rated_amount(@target_currency)
    # end
    @client.update_client_balances
    
  end


end
