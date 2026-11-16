module ApplicationHelper

	include Pagy::Frontend

	def tenant
		current_user.tenant
	end

	# The menu and theme ask for these many times per page, so load them once per request.
	def tenant_module(name)
		@tenant_modules ||= tenant.system_modules.to_a.index_by(&:name)
		@tenant_modules[name]
	end

	def tenant_setting(name)
		@tenant_settings ||= tenant.system_settings.joins(:config_key).pluck("config_keys.name", "system_settings.config_value").to_h
		@tenant_settings[name]
	end

	def unprocessed_notifications
		# Void requests waiting for a decision: this company's only, each request once.
		@unprocessed_notifications ||= current_user ? Notification.waiting_requests(tenant) : []
	end

	def receipting
		tenant_module("Receipting")
	end

	def quotations
		tenant_module("Quotations")
	end

	def invoicing
		tenant_module("Invoicing")
	end

	def multicurrency
		tenant_module("Multicurrency")
	end

	def licensing
		tenant_module("Licensing")
	end

	def cards
		tenant_module("Card Management")
	end

	def expenses
		tenant_module("Expenses")
	end

	def api
		tenant_module("API")
	end

	def inventory
		tenant_module("Inventory")
	end

	def product_pricing
		tenant_setting('Product Pricing')
	end

	def invoice_validity
		tenant_setting('Invoice Validity').to_i
	end

	def product_pricing_short_name
		if product_pricing == 'inclusive'
			'Incl'
		else
			'Excl'
		end
	end

	def attach_invoice_to_receipt
		'NO'
		tenant_setting('Attach Invoice to Receipt')
	end

	def default_user_title
		'User'
		tenant_setting('System Users Title')
	end

	def system_mode
		'client'
	end

	def default_module
		'invoicing'
		tenant_setting('Default Module')
	end

	def license_invoice
		InvoiceCategory.find_by(name: 'License')
	end

	# Start of Themes

	DEFAULT_BRAND_COLOR = "#2f5bd0"

	# Only a valid hex colour reaches the page's CSS.
	def brand_color
		value = theme_background_color.to_s.strip
		value.match?(/\A#(\h{3}|\h{6})\z/) ? value : DEFAULT_BRAND_COLOR
	end

	# Dark or white text, whichever is readable on the company colour.
	def brand_ink
		hex = brand_color.delete("#")
		hex = hex.chars.map { |digit| digit * 2 }.join if hex.length == 3
		red, green, blue = hex.scan(/../).map { |pair| pair.to_i(16) }
		(red * 299 + green * 587 + blue * 114) / 1000 > 150 ? "#1f2933" : "#ffffff"
	end

	def user_initials
		current_user.fullname.split.first(2).map { |name| name[0] }.join.upcase
	end

	def theme_background_color
		'#FFFFFF'
		tenant_setting('Background Color')
	end

	def exchange_rate_update_frequency
	  tenant_setting('Exchange Rate Update Frequency')
	end

end