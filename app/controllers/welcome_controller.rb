require "uri"
require "net/http"

class WelcomeController < ApplicationController

  before_action :authenticate_user!, except: [:register_device]
  before_action :update_exchange_rate

  def index
    @from = Date.today.beginning_of_month
    @to = Date.today
    @start_date = @from  
    @end_date = @to

    Receipt.where('actual_paid = 0').each do |r|
      r.update_attribute(:actual_paid, r.amount_paid)
    end

    Invoice.where(invoice_total: 0).find_each do |v|
      begin
        # Only update if needed (avoid unnecessary writes)
        next if v.invoice_total == v.total

        v.update!(invoice_total: v.total)
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.warn("Skipped duplicate invoice ID=#{v.id}: #{e.message}")
        next
      rescue StandardError => e
        Rails.logger.error("❌ Unexpected error for invoice ID=#{v.id}: #{e.message}")
        next
      end
    end

    populate_missing_settings
    # check if other parameters like banks exists
    if Bank.all.empty?
      redirect_to new_bank_url, notice: "Please add banks"
    end
    # update user_fullname to invoice and receipts
    # Invoice.where('user_fullname IS NULL').each do |invoice|
    #   unless invoice.user_id.nil?
    #     invoice.update_attribute(:user_fullname, invoice.user.user_fullname)

    #   end
    # end

    Invoice.where(user_fullname: nil).find_each do |invoice|
      next if invoice.user_id.nil?
      begin
        invoice.update!(user_fullname: invoice.user.user_fullname)
      rescue ActiveRecord::RecordNotUnique, Mysql2::Error => e
        Rails.logger.warn "⚠️ Skipped duplicate invoice ID=#{invoice.id}: #{e.message}"
        next
      end
    end

    Receipt.where('user_fullname IS NULL').each do |receipt|
      unless receipt.user_id.nil?
        receipt.update_attribute(:user_fullname, receipt.user.user_fullname)
      end
    end
    User.where("user_fullname IS NULL").each do |user|
      user.update_attribute(:user_fullname, user.fullname)
    end
    CreditNote.where("tenant_id IS NULL").each do |credit_note|
      credit_note.update_attribute(:tenant_id, credit_note.user.tenant_id)
    end

    licenses = License.find_by_sql("SELECT * FROM licenses l WHERE NOT EXISTS (SELECT 1 FROM invoices i WHERE i.id = l.invoice_id); ")
    licenses.each_with_index do |license|
      license.destroy
    end
  end

  def dashboard
    invoices = tenant.invoices.active

    @status_counts = Invoice.statuses.keys.index_with do |status|
      invoices.where(status: status).count
    end

    @financial_summary = invoices
      .group(:currency_id)
      .pluck(
        :currency_id,
        Arel.sql("COUNT(*)"),
        Arel.sql("COALESCE(SUM(invoice_total), 0)"),
        Arel.sql("COALESCE(SUM(amount_paid), 0)"),
        Arel.sql("COALESCE(SUM(invoice_total - amount_paid), 0)")
      ).map do |currency_id, count, invoiced, paid, balance|

        currency = Currency.find(currency_id)

        {
          currency: currency.name,
          invoice_count: count,
          total_invoiced: invoiced,
          total_paid: paid,
          outstanding_balance: balance
        }
      end
  end

  def register_device
    url = URI("http://localhost:3000/api/v1/billing/register_devise?deviceID=#{params[:deviceID]}")

    http = Net::HTTP.new(url.host, url.port);
    request = Net::HTTP::Get.new(url)

    response = http.request(request)
    puts response.read_body
  end

  def refresh
    License.active.where(paid: false).all.each do |license|
      puts("*** #{license.client_id}")
      begin
        c = Client.find(license.client_id)
        puts("********** #{license.validate_paid}")
      rescue ActiveRecord::RecordNotFound => e
        puts("client does not exist")
      end
    end

    invoices = Invoice.active.where("rate <= 0")
    transactions = Transaction.where("rate <= 0")
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
    transactions.each do |tr|
      transaction_date = tr.transaction_date 
      puts("#{tr.client.name}*** transaction #{tr.id} #{tr.transaction_date} - #{tr.rate}")
      unless ExchangeRate.active_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency).nil?
        tr.update(rate: ExchangeRate.active_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency))
      else
        tr.update(rate: 1)
      end
    end
    redirect_to root_url, notice: "System refreshed successfully"
  end

  private

  def populate_missing_settings
    product_pricing = ConfigKey.find_by(name: "Product Pricing")
    logo_path = ConfigKey.find_by(name: "Logo Path")
    invoice_validity = ConfigKey.find_by(name: "Invoice Validity")
    background_color = ConfigKey.find_by(name: "Background Color")
    text_color = ConfigKey.find_by(name: "Text Color")
    theme_category = SettingCategory.find_by(name: "Themes")
    receipt_invoice = ConfigKey.find_by(name: "Attach Invoice to Receipt")
    base_currency = ConfigKey.find_by(name: "Base Currency")
    exchange_rate_update = ConfigKey.find_by(name: "Exchange Rate Update Frequency")
    system_users_title = ConfigKey.find_by(name: "System Users Title")
    default_module = ConfigKey.find_by(name: "Default Module")
    if theme_category.nil?
      SettingCategory.create name: 'Themes'
    end
    if system_users_title.present?
      user_title = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: system_users_title.id)
      if user_title.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: system_users_title.id, config_value: 'User')
      end
    else
      ConfigKey.create(name: "System Users Title", setting_category_id: 3)
      user_title = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: system_users_title.id)
      if user_title.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: system_users_title.id, config_value: 'User')
      end      
    end
    if exchange_rate_update.present?
      exchange_rate = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: exchange_rate_update.id)
      if exchange_rate.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: exchange_rate_update.id, config_value: 'daily')
      end
    else
      ConfigKey.create(name: "Exchange Rate Update Frequency", setting_category_id: 3)
      exchange_rate = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: exchange_rate_update.id)
      if exchange_rate.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: exchange_rate_update.id, config_value: 'daily')
      end      
    end
    if background_color.present?
      puts("************ background color present #{background_color.name}")
      background_theme = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: background_color.id)
      if background_theme.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: background_color.id, config_value: '#4e73df')
      end
    else
      ConfigKey.create(name: "Background Color", setting_category_id: 4)
      background_theme = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: background_color.id)
      if background_theme.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: background_color.id, config_value: '#4e73df')
      end      
    end
    if text_color.present?
      text_theme = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: text_color.id)
      if text_theme.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: text_color.id, config_value: '#4e73df')
      end
    else
      ConfigKey.create(name: "Text Color", setting_category_id: 4)
      text_theme = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: text_color.id)
      if text_theme.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: text_color.id, config_value: '#4e73df')
      end  
    end
    if receipt_invoice.present?
      receipt_invoice_client = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: receipt_invoice.id)
      if receipt_invoice_client.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: receipt_invoice.id, config_value: 'NO')
      end
    else
      ConfigKey.create(name: "Attach Invoice to Receipt", setting_category_id: 4)
      receipt_invoice_client = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: receipt_invoice.id)
      if receipt_invoice_client.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: receipt_invoice.id, config_value: 'NO')
      end      
    end
    if base_currency.present?
      base = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: base_currency.id)
      if base.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: base_currency.id, config_value: 1)
      end
    else
      ConfigKey.create(name: "Base Currency", setting_category_id: 4)
      base = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: base_currency.id)
      if base.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: base_currency.id, config_value: 1)
      end      
    end
    if default_module.present?
      mod = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: default_module.id)
      if mod.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: default_module.id, config_value: 1)
      end
    else
      ConfigKey.create(name: "Default Module", setting_category_id: 4)
      mod = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: default_module.id)
      if mod.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: default_module.id, config_value: 1)
      end      
    end
    if product_pricing.present?
      vat_setting = SystemSetting.find_by(tenant_id: tenant.id, config_key_id: product_pricing.id)
      if vat_setting.nil?
        SystemSetting.create(tenant_id: tenant.id, config_key_id: product_pricing.id, config_value: 'exclusive')
      end
    else
      ConfigKey.create(name: "Product Pricing", setting_category_id: 1)
    end
    if logo_path.nil?
      ConfigKey.create(name: "Logo Path", setting_category_id: 1)
    end
    if invoice_validity.nil?
      ConfigKey.create(name: "Invoice Validity", setting_category_id: 1)
    end
    if VatType.all.empty?
      VatType.create name: "Vat 15%", rate: 15
      VatType.create name: "Non Vat", rate: 0
    end
  end

end
