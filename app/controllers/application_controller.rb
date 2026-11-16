class ApplicationController < ActionController::Base
	include Pagy::Backend
	include ServerSideTable

	before_action :authenticate_user!
	before_action :configure_permitted_parameters, if: :devise_controller?
	before_action :require_password_change, unless: :devise_controller?
	include Authorization

	rescue_from StandardError, with: :handle_unexpected_error

	rescue_from ActiveRecord::InvalidForeignKey do
		redirect_back fallback_location: root_path, alert: "This record is in use by other records and cannot be deleted.", status: :see_other
	end

	# Expected situations get a plain explanation instead of the general error message,
	# and are not logged as problems. (Declared after StandardError, so they take precedence.)
	rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
	rescue_from ActionController::InvalidAuthenticityToken, with: :handle_expired_form
	rescue_from ActionController::UnknownFormat, ActionView::MissingTemplate, with: :handle_wrong_format

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

	private

	def require_password_change
		redirect_to edit_password_change_path, status: :see_other if current_user&.must_change_password?
	end

	# In production, show people what to do instead of a raw error page.
	def handle_unexpected_error(error)
		raise error if Rails.env.local? || request.format.json?

		logger.error("#{error.class}: #{error.message}\n#{error.backtrace&.first(10)&.join("\n")}")
		SystemEvent.record(kind: "page_error", tenant_id: current_user&.tenant_id, user: current_user, path: request.fullpath,
		                   title: "#{%w[xlsx pdf csv].include?(request.format.symbol.to_s) ? 'Export' : 'Page'} failed: #{controller_name.humanize} › #{action_name.humanize}",
		                   details: ["#{error.class}: #{error.message}", *Rails.backtrace_cleaner.clean(error.backtrace || []).first(5)].join("\n"))
		message = "That could not be completed. Check the details and try again. If it keeps happening, contact your administrator."

		if request.referer.present? && request.referer != request.url
			redirect_back fallback_location: root_path, alert: message, status: :see_other
		else
			render file: Rails.public_path.join("500.html"), status: :internal_server_error, layout: false
		end
	end

	# A deleted record, an old bookmark, or another company's record.
	def handle_not_found(_error = nil)
		return head(:not_found) unless request.format.html?

		redirect_back fallback_location: root_path, status: :see_other,
		              alert: "That record wasn't found. It may have been deleted, or it isn't part of your account."
	end

	# The form was open longer than the session lasts (or the user signed in elsewhere),
	# so its security token no longer matches. Nothing was saved.
	def handle_expired_form(_error = nil)
		return head(:unprocessable_entity) unless request.format.html?

		if user_signed_in?
			redirect_back fallback_location: root_path, status: :see_other,
			              alert: "This page was open for a long time and its session expired, so nothing was saved. Please try again."
		else
			redirect_to new_user_session_path, status: :see_other, alert: "Your session expired. Please sign in again."
		end
	end

	# For example an Excel-only report opened in the browser.
	def handle_wrong_format(_error = nil)
		return head(:not_acceptable) unless request.format.html?

		redirect_back fallback_location: (user_signed_in? ? reports_path : root_path), status: :see_other,
		              alert: "That page isn't available here. If it's a report, use its Export button to download it as Excel."
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
