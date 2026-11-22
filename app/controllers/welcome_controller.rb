require "uri"
require "net/http"

class WelcomeController < ApplicationController

  before_action :authenticate_user!
  before_action :update_exchange_rate

  def index
    @from = Date.today.beginning_of_month
    @to = Date.today
    @start_date = @from
    @end_date = @to

    populate_missing_settings
    return redirect_to(new_bank_url, notice: "Please add banks") if Bank.all.empty?

    # Read-only. The data repairs that used to run here now live in `bin/rails maintenance:repair`.
    @summary = DashboardSummary.new(tenant, validity_days: invoice_validity, frequency: exchange_rate_update_frequency)
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

  # Fills in a missing exchange rate on this company's invoices and statement lines, from
  # the rate that applied on their date. Records with no rate for their date are left as
  # they are (setting 1 would count ZWL as USD) and the count is reported.
  def refresh
    tenant = current_user.tenant
    config = ConfigKey.find_by(name: 'Exchange Rate Update Frequency')
    return redirect_to(root_url, alert: "Set the exchange rate update frequency in Settings first.") unless config

    frequency = tenant.system_settings.find_by(config_key_id: config.id)&.config_value
    fixed = skipped = 0
    tenant.invoices.active.where("rate <= 0").find_each do |inv|
      rate = ExchangeRate.active_exchange_rate(tenant, inv.invoice_date, frequency)
      next skipped += 1 if rate.nil?
      inv.update(rate: rate, converted_rate: 1 / rate)
      fixed += 1
    end
    Transaction.where(tenant_id: tenant.id).where("rate <= 0").find_each do |tr|
      rate = ExchangeRate.active_exchange_rate(tenant, tr.transaction_date, frequency)
      next skipped += 1 if rate.nil?
      tr.update(rate: rate)
      fixed += 1
    end
    message = "Balances refreshed: #{fixed} #{'record'.pluralize(fixed)} updated."
    message += " #{skipped} still have no exchange rate for their date: add those rates under Exchange rates, then refresh again." if skipped.positive?
    redirect_to root_url, notice: message
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
