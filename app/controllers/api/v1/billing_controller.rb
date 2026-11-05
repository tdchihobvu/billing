module Api
  module V1
    class BillingController < ApiController

    	before_action :validate_device, except: [:device_status, :register_devise]
    	# before_action :check_auth, except: [:device_status]
    	# before_action :http_authenticate, except: [:device_status]

      def index
        render json: "Welcome to Billing API v1", status: :ok
      end

      def register_devise
        # get the device id from the device
        @device = Device.find_by(terminal_id: params[:deviceID])
        if @device.present?
          render json: @device.as_json(only: [:terminal_id, :access_token]), status: :ok
        end
      end

      def exchange_rate
        transaction_date = Date.today
        last_update = ExchangeRate.order(transaction_date: :desc).where(tenant_id: tenant.id).first
        unless last_update.nil?
          case exchange_rate_update_frequency
          when 'daily'
            expiry_date = Date.today
          when 'weekly'
            end_date = transaction_date.to_date - 1.week
            exchange_rates = ExchangeRate.order(transaction_date: :asc).where("transaction_date >= '#{end_date}'")
            unless exchange_rates.empty?
              rate = exchange_rates[-1].selling_rate
              expiry_date = exchange_rates[-1].transaction_date + 1.week
            end
          when 'monthly'
            end_date = transaction_date.to_date - 1.month
            exchange_rates = ExchangeRate.order(transaction_date: :asc).where("transaction_date >= '#{end_date}'")
            unless exchange_rates.empty?
              rate = exchange_rates[-1].selling_rate
              expiry_date = exchange_rates[-1].transaction_date + 1.month
            end
          when 'skip day'
            end_date = transaction_date.to_date - 2.days
            exchange_rates = ExchangeRate.order(transaction_date: :asc).where("transaction_date >= '#{end_date}'")
            unless exchange_rates.empty?
              rate = exchange_rates[-1].selling_rate
              expiry_date = exchange_rates[-1].transaction_date + 2.days
            end
          else
            rate = nil
            expiry_date = 'expired'
          end
        end
        rate = ExchangeRate.active_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency)
        unless rate.nil?
          render json: {rate: rate.to_f, expiry_date: expiry_date}, status: :ok
        else
          render json: {status: 'ERROR', message: "Please update exchange rate"}, status: 404
        end
      end

    	def device_status
        # # get the teminal id and the access token
        # access_key = request.headers["Authorization"].to_s.split(' ').last
        # puts "terminal id #{terminalId} *** #{access_key}"
        @device = Device.find_by(terminal_id: terminalId, access_token: access_key)
        if @device.nil?
          render json: {status: 'ERROR', message: 'Device is not registered.'}, status: 404
        else
          if @device.active?
            render json: @device, status: :ok
          else
            render json: {status: @device.status, device: @device.name, message: "Device is registered and status is #{@device.status}"}, status: 203
          end
        end    		
    	end

      def client_registration
        puts "we are here start creating client"
        # validate name 
        puts "#{params[:name]}"
        # check if the client already exists
        unless Client.exists?(name: params[:name])
          @client = Client.new
          @industry = Industry.find_by(name: params[:industry])
          @client_type = ClientType.find_by(name: params[:clientType])
          if @client_type.nil?
            render json: {status: "ERROR", message: "Client type is invalid"}, status: :unprocessable_entity
            return
          else
            @client.client_type_id = @client_type.id
          end
          if @industry.nil?
            other = Industry.find_by(name: 'Other')
            @industry = other
            # render json: {status: "ERROR", message: "Industry is invalid"}, status: :unprocessable_entity
            # return
            @client.industry_id = @other.id
          else
            @client.industry_id = @industry.id
          end
          @client.tenant_id = tenant.id
          @client.name = params[:name]
          @client.address_1 = params[:address]
          @client.location = params[:location]
          @client.city = params[:city]
          @client.country = params[:country]
          @client.email = params[:email]
          @client.phone = params[:phoneNumber]
          @client.cp_mobile = params[:phoneNumber]
          @client.cp_name = params[:contactPerson]
          @client.gps_latitude = params[:gpsLatitude]
          @client.gps_longitude = params[:gpsLongitude]
          @client.source_reference = params[:sourceReferenceNumber]
          @client.terminal_id = current_device.terminal_id
          last = tenant.clients.order(client_account_number: :asc)[-1]
          if last.nil?
            @client.client_account_number = "10001"
          else
            @client.client_account_number = last.client_account_number.next
          end
          if @client.save
            render json: {status: "SUCCESS", message: "Client saved successfully"}, status: :ok
          else
            errors = []
            @client.errors.each do |e|
              errors << e.full_message
            end
            render json: {status: :unprocessable_entity, message: "#{errors}"}, status: :unprocessable_entity
          end
        else
          render json: {status: "ERROR", message: "Client already exists!"}, status: :unprocessable_entity
        end
      end

      def new_branch
        client_name = params[:clientName].to_s.strip
        license_option = LicenseOption.find_by(name: 'Annually')

        return render_error("Please provide client name.", :unprocessable_entity) if client_name.blank?

        # Find existing client under the current tenant
        @client = tenant.clients.where("TRIM(name) = ?", client_name).first

        return render_error(
          "Client '#{client_name}' could not be found.",
          :not_found
        ) if @client.nil?

        # Create branch for the existing client
        branch = @client.branches.new(branch_params)
        branch.tenant_id = current_device.tenant_id
        branch.license_category_id = 1
        branch.license_option_id = license_option.id
        if branch.save
          render json: {
            status: "SUCCESS",
            message: "Branch created successfully.",
            client: {
              id: @client.id,
              name: @client.name
            },
            branch: branch
          }, status: :created
        else
          render_error(branch.errors.full_messages, :unprocessable_entity)
        end
      end      

    	def open_shift
    		# authenticate_user!
    		# check if the district is included
    		unless params[:District].nil? || params[:District].empty?
    			# search if the district exists in the database
    			@district = District.find_by(name: params[:District])
    			unless @district.nil?
		    		# check if there is an open shift
		    		# if active_shift.nil?
		    			unless current_user.nil?
								new_shift = Shift.new
								new_shift.shift_id = "#{current_device.terminal_id}#{(Time.now + 2.hours).strftime("%d%m%Y%H%M")}"  
								new_shift.username = current_user.username
								new_shift.device_id = current_device.id
								new_shift.region_id = current_device.regional_office.region_id
								new_shift.tenant_id = current_device.tenant_id
								new_shift.district_id = @district.id
								new_shift.start_time = Time.now + 2.hours
								new_shift.active = true
								new_shift.start_shift_synced = true
								if new_shift.save 
									render json: new_shift, status: :created
                  # check existing shifts
                  current_device.shifts.where("id != #{new_shift.id}").update!(active: false, end_time: Time.now)
								else
									errors = []
									new_shift.errors.each do |e|
										errors << e
									end
									render json: {status: 'ERROR', message: "Ooops! Error shift could not open. #{errors}"}, status: :unprocessable_entity
								end
			    		else
			    			render json: {status: 'ERROR', message: "You are required to login first, before you continue."}, status: :unauthorized
			    		end
		    		# else
		    		# 	render json: {status: 'ERROR', message: "You have an open shift, either close existing shift or continue transacting.", shiftId: active_shift.shift_id}, status: :unauthorized
		    		# end
		    	else
		    		render json: {status: 'ERROR', message: 'The district name provided does not exist or is invalid.'}, status: 404
		    	end
	    	else
	    		render json: {status: 'ERROR', message: 'Please provide the District you are operating from.'}, status: 404
	    	end
    	end

      def new_invoice
        # check if the shift is valid
        if params[:shiftId].nil? || params[:shiftId].empty?
          render json: {status: 'ERROR', message: 'ShiftId is empty'}, status: 404
          # return
        else
          # check if the shift exists
          @shift = Shift.find_by(shift_id: params[:shiftId])
          unless @shift.nil?
            # check if the shift is open
              # check if the client exists
              if Client.exists?(name: params[:clientName], tenant_id: current_device.tenant_id)
                @client = Client.find_by(name: params[:clientName], tenant_id: current_device.tenant_id)
                @currency = Currency.find_by(name: params[:invoiceCurrency])
                unless current_user.nil?
                  unless Invoice.exists?(tenant_id: current_device.tenant_id, client_id: @client.id, source_reference: params[:invoiceReference])
                    # return render json: { status: "error", message: "Renewal Month cannot be blank" } if params[:renewalMonth].nil?
                  begin
                    Invoice.transaction do
                      invoice = Invoice.new(
                        invoice_category_id: 2,
                        client_id: @client.id,
                        currency_id: @currency&.id,
                        user_id: current_user.id,
                        invoice_date: params[:invoiceDateTime].to_date,
                        tenant_id: current_device.tenant_id,
                        shift_id: @shift.id,
                        device_id: current_device.id,
                        gps_longitude: params[:gpsLongitude],
                        gps_latitude: params[:gpsLatitude],
                        source_reference: params[:invoiceReference],
                        is_synced: true,
                        invoice_total: params[:amountDue].to_f,
                        product_pricing: 'none'
                      )

                      # Generate invoice number
                      config_key = ConfigKey.find_by!(name: 'Invoice No.')
                      setting = tenant.system_settings.find_by!(config_key_id: config_key.id)

                      last_invoice = Invoice.where(
                        tenant_id: current_device.tenant_id,
                        is_proforma: false
                      ).order(:invoice_number).lock.last

                      invoice.invoice_number =
                        last_invoice.present? ? last_invoice.invoice_number.next : setting.config_value

                      invoice.save!

                      option = LicenseOption.find_by(name: params[:licenseOption]) ||
                               LicenseOption.find_by!(name: 'Monthly')

                      category = LicenseCategory.find_by(name: params[:licenseCategory]) ||
                                 LicenseCategory.first!

                      license = invoice.create_license!(
                        license_category: category,
                        license_option: option,
                        renewal_date: params[:renewalMonth],
                        quantity: 1,
                        amount: params[:amountDue].to_f,
                        special_days: params[:days]
                      )
                    end

                    render json: { status: "SUCCESS" }

                  rescue ActiveRecord::RecordInvalid => e
                    Rails.logger.error e.record.errors.full_messages
                    render json: {
                      status: :unprocessable_entity,
                      message: e.record.errors.full_messages
                    }, status: :unprocessable_entity
                  end
                  else
                    render json: {status: 'ERROR', message: "Invoice for #{@client.name} with reference #{params[:invoiceReference]} already exists!"}, status: :unprocessable_entity
                  end
                else
                 render json: {status: "ERROR", message: "Please log in"}, status: :unauthorized 
                end
              else
                render json: {status: "ERROR", message: "Client record could not be found"}, status: 404
              end
          else
            # check if the user does not have an active shift on the portal
            if current_device.active_shift(current_user)
              render json: {status: "ERROR", message: "You currently have an open shift with ID #{current_device.active_shift(current_user).shift_id} close the shift to start transacting."}, status: 404
            else
              # get the shift id to create a new shift
              n_shift = Shift.new
              # get the district id
              @district = District.find_by(name: params[:district])
              puts("***************************** the district posted from #{current_device.terminal_id} >>>> is #{params[:district]} with object #{@district}")
              unless @district.nil?
                puts("status: 'SUCCESS', message: 'Creating shift with #{params[:shiftId]} for district #{@district.name}', status: :ok")
                n_shift.shift_id = params[:shiftId]   
                n_shift.username = current_user.username
                n_shift.device_id = current_device.id
                n_shift.district_id = @district.id
                n_shift.region_id = @district.region_id
                n_shift.tenant_id = current_device.tenant_id
                n_shift.start_time = params[:invoiceDateTime]
                n_shift.active = true
                n_shift.start_shift_synced = true
                if n_shift.save 
                  # check if the client exists
                  if Client.exists?(name: params[:clientName], tenant_id: current_device.tenant_id)
                    @client = Client.find_by(name: params[:clientName], tenant_id: current_device.tenant_id)
                    @currency = Currency.find_by(name: params[:invoiceCurrency])
                    unless current_user.nil?
                      unless Invoice.exists?(tenant_id: current_device.tenant_id, client_id: @client.id, source_reference: params[:invoiceReference])
                        invoice = Invoice.new
                        invoice.invoice_category_id = 2
                        invoice.client_id = @client.id
                        invoice.currency_id = @currency.id unless @currency.nil?
                        invoice.user_id = current_user.id
                        invoice.invoice_date = params[:invoiceDateTime].to_date
                        invoice.is_proforma = false
                        # auto generate invoice number
                        unless tenant.system_settings.empty?
                          inv_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Invoice No.').id).config_value
                          invoices = Invoice.order('invoice_number Asc').where(is_proforma: false, tenant_id: current_device.tenant_id)
                          if invoices.empty?
                            invoice.invoice_number = inv_format
                          else
                            invoice.invoice_number = invoices[-1].invoice_number.next
                          end
                        end
                        invoice.tenant_id = current_device.tenant_id
                        invoice.shift_id = n_shift.id
                        invoice.device_id = current_device.id 
                        invoice.gps_longitude = params[:gpsLongitude]
                        invoice.gps_latitude = params[:gpsLatitude]
                        invoice.source_reference = params[:invoiceReference]
                        invoice.is_synced = true
                        # invoice.bank_id = tenant.banks[0].id
                        invoice.product_pricing = 'none'
                        @vat_type = VatType.find_by(name: 'Non VAT')
                        category = LicenseCategory.first
                        option = LicenseOption.find_by(name: 'Monthly')
                        unless params[:licenseOption].nil?
                          option = LicenseOption.find_by(name: "#{params[:licenseOption]}")
                        end
                        unless params[:licenseCategory].nil?
                          category = LicenseCategory.find_by(name: "#{params[:licenseCategory]}")
                        end
                        1.times {invoice.invoice_items.build(description: params[:itemDescription], quantity: 1, unit_price: params[:amountDue].to_f, vat_type_id: @vat_type.id)}
                        # 1.times {invoice.build_license(license_category_id: category.id, license_option_id: option.id, renewal_date: params[:renewalMonth], quantity: 1, amount: params[:amountDue].to_f, special_days: params[:days])}
                            
                        if invoice.save
                          render json: {status: "SUCCESS", message: "Invoice saved successfully."}, status: :ok
                        else
                          errors = []
                          invoice.errors.each do |e|
                            errors << e.full_message
                          end
                          render json: {status: :unprocessable_entity, message: "#{errors}"}, status: :unprocessable_entity
                        end
                      else
                        render json: {status: 'ERROR', message: "Invoice for #{@client.name} with reference #{params[:invoiceReference]} already exists!"}, status: :unprocessable_entity
                      end
                    else
                     render json: {status: "ERROR", message: "Please log in"}, status: :unauthorized 
                    end
                  else
                    render json: {status: "ERROR", message: "Client record could not be found"}, status: 404
                  end
                else
                  errors = []
                  n_shift.errors.each do |e|
                    errors << e
                  end
                  render json: {status: 'ERROR', message: "Ooops! Error shift could not open. #{errors}"}, status: :unprocessable_entity
                end
              else
                render json: {status: 'ERROR', message: "District #{params[:district]} is not valid."}, status: :unprocessable_entity
              end
            end
          end
        end        
      end

      def new_receipt
        return render_error("ShiftId is empty", :not_found) if params[:shiftId].blank?

        @shift = Shift.find_by(shift_id: params[:shiftId])

        if @shift.nil?
          @shift = create_shift
          return unless @shift
        end

        create_receipt
      end

      def void_invoice
        # get the invoice parameteres reference and reason for void
        source_reference = params[:invoiceReference]
        void_reason = params[:voidReason]
        @invoice = Invoice.find_by(source_reference: source_reference, user_id: current_device.user_id)
        puts("*********** invoice #{@invoice}")
        unless @invoice.nil?
          if @invoice.deleted?
            render json: {status: "ERROR", message: "Invoice with source reference #{source_reference} is already marked as void."}, status: 404
          else
            # check if the reason is not null
            unless params[:voidReason].nil?
              # create notification for the administrators
              notification = Notification.new  
              notification.message = "#{current_device.user.user_fullname} has requested to void invoice with reference number #{source_reference} (#{void_reason})"
              notification.process_url = "#{request.base_url}/invoices/void_invoice?id=#{@invoice.id}&void_reason=#{CGI.escape void_reason}"
              notification.user_id = current_device.user.id
              if notification.save
                render json: {status: "SUCCESS", message: "Request to void Invoice #{source_reference} has been successful", reference_number: @invoice.source_reference}, status: :ok
              else
                render json: {status: :unprocessable_entity, message: "Failed to send request"}, status: :unprocessable_entity
              end
            else
              render json: {status: :unprocessable_entity, message: "Please enter the reason for void"}, status: :unprocessable_entity
            end
          end
        else
          render json: {status: "ERROR", message: "Invoice with source reference #{source_reference} could not be found for user #{current_device.user.username}"}, status: 404
        end
      end

      def void_receipt
        source_reference = params[:receiptReference]
        void_reason = params[:voidReason]
        # @receipt = Receipt.find_by(sync_reference: source_reference, user_id: current_device.user.id)
        @receipt = Receipt.where("(source_reference = #{source_reference} AND user_id = #{current_device.user_id}) OR (sync_reference = #{source_reference} AND user_id = #{current_device.user_id})").first
        unless @receipt.nil?
          if @receipt.deleted?
            render json: {status: "ERROR", message: "Receipt with source reference #{source_reference} is already marked as void."}, status: 404
          else
            unless params[:voidReason].nil?
              if @receipt.update(deleted: true, void_date: Date.today, void_reason: void_reason)
                unless @receipt.invoice_reference.nil?
                  invoice = Invoice.find_by(source_reference: @receipt.invoice_reference)
                  unless invoice.nil?
                    invoice.update(status: 'Not Paid', paid: false, amount_paid: invoice.total_paid)
                  end
                end
                user = current_device.user
                ipaddress = request.remote_ip
                device_name = "#{current_device.name}#{current_device.serial_number}-#{request.user_agent}"
                activity = "#{user.user_fullname} voided the receipt with invoice number #{@receipt.reference_number} and source reference number #{@receipt.sync_reference}"
                user_log(user,activity,ipaddress,device_name)
                render json: {status: "SUCCESS", message: "Receipt #{source_reference} successfully voided from the portal.", reference_number: @receipt.source_reference}, status: :ok
              else
                render json: {status: :unprocessable_entity, message: "Failed to void the receipt"}, status: :unprocessable_entity
              end
            else
              render json: {status: :unprocessable_entity, message: "Please enter the reason for void"}, status: :unprocessable_entity
            end
          end
        else
          render json: {status: "ERROR", message: "Receipt with source reference #{source_reference} could not be found for user #{current_device.user.username}"}, status: 404
        end
      end

    	def close_shift
    		# authenticate_user!
    		# get the shift using the shift id
    		shift = Shift.find_by(shift_id: params[:shiftId], username: params[:username])
    		if shift  
    			if shift.close_shift(params[:end_time])
    				render json: {status: 'SUCCESS', message: "Shift successfully closed at #{shift.end_time}"}, status: :ok
    			else
    				render json: {status: 'ERROR', message: "Ooops! Error closing shift."}, status: :unprocessable_entity
    			end
    		else
    			render json: {status: 'ERROR', message: "Shift could not be found on the portal."}, status: 204
    		end
    	end

      def client_invoices
        # provide client parameters
        client = params[:client_name]
        unless client.nil?
          @client = Client.find_by(name: client)
          unless @client.nil?
            render json: @client.invoices.active, each_serializer: InvoiceSerializer, root: true
          else
            render json: {status: 'ERROR', message: "Client details could not be found."}, status: 204
          end
        else
          render json: {status: 'ERROR', message: "Please provide client name."}, status: 204
        end
      end

      def user_invoices
        # derive the username from the device
        unless current_device.nil?
          @user = current_device.user
          @user.invoices.joins(:license).distinct.each do |u|
            puts("*** #{u.id},#{u.invoice_date},#{u.source_reference},#{u.sync_reference}")
          end
          render json: @user.invoices.active.joins(:license).distinct, each_serializer: InvoiceSerializer, root: true
        else
          render json: {status: "ERROR", message: "Device could not be found or does not exist."}, status: 203
        end
      end

      def user_receipts
        # derive the username from the device
        unless current_device.nil?
          @user = current_device.user
          render json: @user.receipts.active.where.not(invoice_reference: nil), each_serializer: ReceiptSerializer, root: true
        else
          render json: {status: "ERROR", message: "Device could not be found or does not exist."}, status: 203
        end
      end

		  def customers_list
	      @clients = tenant.clients
	      render json: @clients, each_serializer: ClientSerializer, root: false
		  end

		  def company_details
		  	render json: tenant, status: :ok
		  end

		  def tariffs
		  	@tarrifs = tenant.tarrifs
				render json: @tarrifs, each_serializer: TarrifSerializer, root: false
		  end

		  def users
		      @users = tenant.users
		      render json: @users, each_serializer: UserSerializer, root: false
		  end

		  def regions_list
	      @regions = Region.all
	      render json: @regions, each_serializer: RegionSerializer, root: false
		  end

		  def districts_list
	      @districts = District.all
	      render json: @districts, each_serializer: DistrictSerializer, root: false
		  end

      def industries_list
        @industries = Industry.where(tenant_id: tenant.id)
        render json: @industries, each_serializer: IndustrySerializer, root: false        
      end

      def client_types
        @client_types = ClientType.all
        render json: @client_types, each_serializer: ClientTypeSerializer, root: false        
      end

      def license_options
        @license_options = LicenseOption.all
        render json: @license_options, each_serializer: LicenseOptionSerializer, root: false        
      end

      def license_categories
        @license_categories = LicenseCategory.all
        render json: @license_categories, each_serializer: LicenseCategorySerializer, root: false        
      end

      def upload_invoices    
        Invoice.import_invoices(params[:file],tenant)
      end

      def upload_receipts  
        Receipt.import_receipts(params[:file],tenant,default_currency,exchange_rate_update_frequency)
      end

      private

      def device_setting_params
        params.require(:device_setting).permit(:device_id, :device_token)
      end

      def user_log(user,activity,ipaddress,device_name)
        UserLog.create(user_id: user.id, activity: activity, ipaddress: ipaddress, device_name: device_name, perfomed_at: Time.now + 2.hours)
      end

      def branch_params
        params.require(:branch).permit(
          :client_id,
          :tenant_id,
          :name,
          :address_1,
          :address_2,
          :location,
          :city,
          :country
        )
      end

      def create_receipt
        return render_error("Please log in", :unauthorized) if current_user.nil?

        @client = Client.find_by(
          name: params[:clientName],
          tenant_id: current_device.tenant_id
        )

        return render_error(
          "Client record could not be found",
          :not_found
        ) if @client.nil?

        return render_error(
          "Receipt with Ref No. #{params[:receiptNumber]} for #{current_device.name} already exists!",
          :conflict
        ) if Receipt.exists?(
          device_id: current_device.id,
          source_reference: params[:receiptNumber]
        )

        @currency = Currency.find_by(name: params[:currencyUsed])
        @payment_form = PaymentForm.find_by(name: params[:transactionType])

        return render_error(
          "Currency is invalid",
          :unprocessable_entity
        ) if @currency.nil?

        receipt = build_receipt
        return if receipt.nil?
        Rails.logger.info "=== RECEIPT TYPE DEBUG ==="
        Rails.logger.info "receipt_type: #{receipt.receipt_type.inspect}"
        Rails.logger.info "receipt_type_before_type_cast: #{receipt.receipt_type_before_type_cast.inspect}"
        Rails.logger.info "payment?: #{receipt.payment?}"
        Rails.logger.info "reason: #{receipt.reason.inspect}"
        Rails.logger.info "=========================="

        Receipt.transaction do
          receipt.save!

          receipt.update!(
            actual_paid: receipt.amount_paid
          )

          receipt.invoice&.update_balance
        end

        render_success("Receipt saved successfully.")
        rescue ActiveRecord::RecordInvalid => e
        render_error(
          e.record.errors.full_messages,
          :unprocessable_entity
        )
      end

      def build_receipt
        receipt = Receipt.new

        receipt.client_id = @client.id
        receipt.currency_id = @currency.id
        receipt.payment_form_id = @payment_form.id unless @payment_form.nil?
        receipt.amount = params[:amountPaid].to_d
        receipt.user_id = current_user.id
        receipt.transaction_date = params[:transactionDateTime].to_date

        receipt.reference_number = generate_receipt_number
        receipt.tenant_id = @client.tenant_id
        receipt.receipt_type = 'Payment'

        receipt.description = params[:businessNature].presence || "None"

        receipt.transaction_source = current_device.model
        receipt.transaction_source_id = current_device.terminal_id
        receipt.business_nature = params[:businessNature]

        receipt.shift_id = @shift.id
        receipt.device_id = current_device.id
        receipt.gps_longitude = params[:gpsLongitude]
        receipt.gps_latitude = params[:gpsLatitude]
        receipt.source_reference = params[:receiptNumber]
        receipt.is_synced = true

        # Attach invoice FIRST
        return unless attach_invoice(receipt)

        # Now invoice is available
        receipt.rate = receipt_rate(receipt)

        receipt
      end


      def attach_invoice(receipt)
        invoice_reference = params[:invoice_reference].to_s.strip

        invoice = Invoice.find_by(
          source_reference: invoice_reference,
          client_id: @client.id
        )

        if tenant.attach_invoice_to_receipt? && invoice.nil?
          render_error(
            "A valid invoice reference is required for this receipt.",
            :unprocessable_entity
          )

          return
        end

        receipt.invoice = invoice if invoice.present?
        receipt.invoice_reference =
          invoice&.source_reference || invoice_reference.presence

        receipt
      end

      def generate_receipt_number
        rec_format = tenant.system_settings
                           .joins(:config_key)
                           .find_by(config_keys: { name: "Receipt No." })
                           &.config_value

        return if rec_format.blank?

        last_receipt = tenant.receipts
                              .order(reference_number: :desc)
                              .first

        last_receipt&.reference_number&.next || rec_format
      end

      def receipt_rate(receipt)
        invoice = receipt.invoice

        # Same currency: no conversion required
        return 1 if invoice.present? && receipt.currency_id == invoice.currency_id

        # Different currencies: get the rate for the transaction date
        get_rate(receipt.currency, receipt.transaction_date)
      end

      def create_shift
        # User already has an active shift
        active_shift = current_device.active_shift(current_user)

        if active_shift
          render_error(
            "You currently have an open shift with ID #{active_shift.shift_id} close the shift to start transacting.",
            :not_found
          )

          return nil
        end

        district = District.find_by(name: params[:district])

        unless district
          render_error(
            "District #{params[:district]} is not valid.",
            :unprocessable_entity
          )

          return nil
        end

        shift = Shift.new(
          shift_id: params[:shiftId],
          username: current_user.username,
          device_id: current_device.id,
          district_id: district.id,
          region_id: district.region_id,
          tenant_id: current_device.tenant_id,
          start_time: params[:transactionDateTime],
          active: true,
          start_shift_synced: true
        )

        if shift.save
          shift
        else
          render_error(
            "Ooops! Error shift could not open. #{shift.errors.full_messages.join(', ')}",
            :unprocessable_entity
          )

          nil
        end
      end

      def render_success(message)
        render json: {
          status: "SUCCESS",
          message: message
        }, status: :ok
      end

      def render_error(message, status)
        render json: {
          status: "ERROR",
          message: message
        }, status: status
      end

    end
  end
end

## Solutions to auto increament id in clients table with already existing records in console
# ActiveRecord::Base.connection.execute(<<~SQL)
#   SELECT setval(
#     pg_get_serial_sequence('clients', 'id'),
#     COALESCE(MAX(id), 1),
#     MAX(id) IS NOT NULL
#   )
#   FROM clients;
# SQL