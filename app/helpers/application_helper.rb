module ApplicationHelper

	def tenant
		current_user.tenant
	end

	def receipting
		tenant.system_modules.find_by(name: "Receipting")
	end

	def quotations
		tenant.system_modules.find_by(name: "Quotations")
	end

	def invoicing
		tenant.system_modules.find_by(name: "Invoicing")
	end

	def multicurrency
		tenant.system_modules.find_by(name: "Multicurrency")
	end

	def licensing
		tenant.system_modules.find_by(name: "Licensing")
	end

	def cards
		tenant.system_modules.find_by(name: "Card Management")
	end

	def expenses
		tenant.system_modules.find_by(name: "Expenses")
	end

	def api
		tenant.system_modules.find_by(name: "API")
	end

	def inventory
		tenant.system_modules.find_by(name: "Inventory")
	end

	def product_pricing
		config_key = ConfigKey.find_by(name: 'Product Pricing')
		tenant.system_settings.find_by(config_key_id: config_key.id).config_value		
	end

	def invoice_validity
		config_key = ConfigKey.find_by(name: 'Invoice Validity')
		tenant.system_settings.find_by(config_key_id: config_key.id).config_value.to_i		
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
		config_key = ConfigKey.find_by(name: 'Attach Invoice to Receipt')
		unless tenant.system_settings.find_by(config_key_id: config_key.id).nil?
			tenant.system_settings.find_by(config_key_id: config_key.id).config_value	
		end
	end

	def default_user_title
		'User'
		config_key = ConfigKey.find_by(name: 'System Users Title')
		unless tenant.system_settings.find_by(config_key_id: config_key.id).nil?
			tenant.system_settings.find_by(config_key_id: config_key.id).config_value	
		end
	end

	def system_mode
		'client'
	end

	def default_module
		'invoicing'
		config_key = ConfigKey.find_by(name: 'Default Module')
		unless tenant.system_settings.find_by(config_key_id: config_key.id).nil?
			tenant.system_settings.find_by(config_key_id: config_key.id).config_value
		end	
	end

	def license_invoice
		InvoiceCategory.find_by(name: 'License')
	end

	# Start of Themes

	def theme_background_color
		'#FFFFFF'
		config_key = ConfigKey.find_by(name: 'Background Color')
		unless tenant.system_settings.find_by(config_key_id: config_key.id).nil?
			tenant.system_settings.find_by(config_key_id: config_key.id).config_value	
		end
	end

	def exchange_rate_update_frequency
	  config = ConfigKey.find_by(name: 'Exchange Rate Update Frequency')
	  return nil unless config

	  setting = tenant.system_settings.find_by(config_key_id: config.id)
	  setting&.config_value
	end

end