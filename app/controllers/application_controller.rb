class ApplicationController < ActionController::Base
	include Pagy::Backend
	before_action :authenticate_user!
	before_action :configure_permitted_parameters, if: :devise_controller?

	def tenant
		current_user.tenant
	end

	def template
		config_key = ConfigKey.find_by(name: 'Invoice Template')
		SystemSetting.find_by(tenant_id: tenant.id, config_key_id: config_key.id).config_value
	end

	def statement_start_date
		Date.today.beginning_of_year - 1.year
	end

	def product_pricing
		config_key = ConfigKey.find_by(name: 'Product Pricing')
		SystemSetting.find_by(tenant_id: tenant.id, config_key_id: config_key.id).config_value		
	end

	def invoice_validity
		config_key = ConfigKey.find_by(name: 'Invoice Validity')
		tenant.system_settings.find_by(config_key_id: config_key.id).config_value.to_i		
	end

	def default_transaction_source
		"BaseApplication"
	end

	def base_currency
		# config = ConfigKey.find_by(name: 'Base Currency')
		# tenant.system_settings.find_by(config_key_id: config.id).config_value
		Currency.find_by(name: 'USD')
	end

	def logo_path
		config = ConfigKey.find_by(name: 'Logo Path')
		tenant.system_settings.find_by(config_key_id: config.id).config_value
	end

	def system_mode
		'client'
	end

	def default_module
		'billing'
	end

	def exchange_rate_update_frequency
		config = ConfigKey.find_by(name: 'Exchange Rate Update Frequency')
		tenant.system_settings.find_by(config_key_id: config.id).config_value
	end

	def default_user_title
		config = ConfigKey.find_by(name: 'System Users Title')
		tenant.system_settings.find_by(config_key_id: config.id).config_value
	end

	def update_exchange_rate
		# check exchange rate update frequency
		last_update = ExchangeRate.order(transaction_date: :desc).where(tenant_id: tenant.id).first
		if last_update.nil?
			redirect_to exchange_rates_url, notice: "Please update exchange rate"
		else
		  case exchange_rate_update_frequency
		  when 'daily'
		      if ExchangeRate.where(transaction_date: Date.today).empty?
		        redirect_to exchange_rates_url, notice: "Please update exchange rate. Last updated on #{last_update.transaction_date.strftime("%d %b %Y")}"
		      end
		  when 'weekly'
		  	if (last_update.transaction_date + 7.days) <= Date.today
		        redirect_to exchange_rates_url, notice: "Please update exchange rate. Last updated on #{last_update.transaction_date.strftime("%d %b %Y")}"
		  	end
		  when 'monthly'
		  	if (last_update.transaction_date + 30.days) <= Date.today
		        redirect_to exchange_rates_url, notice: "Please update exchange rate. Last updated on #{last_update.transaction_date.strftime("%d %b %Y")}"
		  	end
		  when 'skip day'
		  	if (last_update.transaction_date + 2.days) <= Date.today
		        redirect_to exchange_rates_url, notice: "Please update exchange rate. Last updated on #{last_update.transaction_date.strftime("%d %b %Y")}"
		  	end
		  else
		      if ExchangeRate.where(transaction_date: Date.today).empty?
		        redirect_to exchange_rates_url, notice: "Please update exchange rate. Last updated on #{last_update.transaction_date.strftime("%d %b %Y")}"
		      end
		  end
		end
	end

	protected

	def configure_permitted_parameters
		devise_parameter_sanitizer.permit(:sign_up, keys: [:firstname, :lastname, :username, :tenant_id, :role, :email])
    	devise_parameter_sanitizer.permit(:account_update, keys: [:firstname, :lastname, :email, :role])
	end

	def user_log(user,activity,ipaddress,device_name)
		UserLog.create(user_id: user.id, activity: activity, ipaddress: ipaddress, device_name: device_name, perfomed_at: Time.now + 2.hours)
	end
end
