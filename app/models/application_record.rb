class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def base_currency
    # Example: pull from config, ENV, or DB
    @base_currency ||= Currency.find_by(name: 'USD')
  end

  def exchange_rate_update_frequency
    config = ConfigKey.find_by(name: 'Exchange Rate Update Frequency')
    return nil unless config

    setting = tenant.system_settings.find_by(config_key_id: config.id)
    setting&.config_value
  end

end
