class SystemSettingsController < ApplicationController

  def index
    @tenant = tenant
    ConfigKey.all.each do |k|
      # unless k.persisted?
      if @tenant.system_settings.find_by(config_key_id: k.id).nil?
        @tenant.system_settings.build(config_key_id: k.id)
      end
      # end
    end
  end
end
