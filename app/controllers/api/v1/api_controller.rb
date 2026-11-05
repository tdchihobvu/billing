module Api
  module V1
    class ApiController < ActionController::Base

      protect_from_forgery with: :null_session

      def default_currency
        Currency.find_by(name: 'USD')
      end

      def get_rate(currency,transaction_date)
        ExchangeRate.active_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency)
      end

      def tenant
        Tenant.find(current_device.tenant_id)
      end

      def terminalId
        request.headers["TerminalId"]
      end

      def access_key
        request.headers["accessToken"]
      end

      def current_user
        user = User.find_by(username: params[:username])
        if user.nil? 
          nil
        end
        user
      end

      def current_device
        Device.find_by(terminal_id: terminalId)
      end

      def active_shift
        Shift.find_by(device_id: current_device.id, tenant_id: tenant.id, end_time: nil)
      end

      def license_invoice
        InvoiceCategory.find_by(name: 'License')
      end

      def validate_device
        # # get the teminal id and the access token
        # access_key = request.headers["Authorization"].to_s.split(' ').last
        # puts "terminal id #{terminalId} *** #{access_key}"
        @device = Device.find_by(terminal_id: terminalId, access_token: access_key)
        if @device.nil?
          render json: {status: 'ERROR', message: 'Device is not registered.'}, status: 404
        else
          if @device.active == false
            render json: {status: @device.status, device: @device.name, message: "Device is registered and status is #{@device.status}"}, status: :ok
          end
        end
      end

      def get_device
        @device = Device.find_by(terminal_id: terminalId, access_token: access_key)
        if @device.nil?
          nil
        else
          if @device.active == false
            @device
          else
            nil
          end
        end        
      end

      def exchange_rate_update_frequency
        config = ConfigKey.find_by(name: 'Exchange Rate Update Frequency')
        tenant.system_settings.find_by(config_key_id: config.id).config_value
      end

      # def check_auth
      #   authenticate_or_request_with_http_basic do |username,password|
      #     resource = User.find_by_email(username)
      #     if resource.valid_password?(password)
      #       sign_in :user, resource
      #     end
      #   end
      # end

      private
      
    end
  end
end