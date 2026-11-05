class ClientsController < ApplicationController
  before_action :set_client, only: %i[ show edit update destroy account_statement post_receipt add_branches reset_statement ]

  # GET /clients
  def index
    @clients = current_user.tenant.clients.includes(:client_type, :industry).order(name: :asc)
  end

  # GET /clients/1
  def show
    @start_date = statement_start_date
    @end_date = Date.today
    @client.update_client_balances
    @currency = @client.currency
    @target_currency = @currency
  end

  def add_branches
    if @client.branches.empty?
      20.times {@client.branches.build(tenant_id: @client.id, license_category_id: 1, license_option_id: 1)}
    else
      10.times {@client.branches.build(tenant_id: @client.id, license_category_id: 1, license_option_id: 1)}
    end
  end

  def upload_branches
    @client = Client.find(params[:client_id])
    unless params[:file].nil?
      Client.import_branches(params[:client_id],params[:file])
      flash[:notice] = "Branches successfully upload."
    else
      flash[:notice] = "File cannot be blank."
    end
    redirect_to add_branches_clients_url(id: @client)    
  end

  def delete_branch
    @client = Client.find(params[:client_id])
    @branch = Branch.find(params[:branch_id])
    if @branch.update_attribute(:active, false)
      flash[:notice] = "Branch Successfully removed."
    end
    redirect_to @client
  end

  def post_receipt
    @receipt = Receipt.new 
    @receipt.client_id = @client.id
    @receipt.transaction_date = Date.today
    @receipt.user_id = current_user.id

    # auto generate receipt number
    unless current_user.tenant.system_settings.empty?
      rec_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Receipt No.').id).config_value
      last = current_user.tenant.receipts.order(reference_number: :asc)[-1]
      if last.nil?
        @receipt.reference_number = rec_format
      else
        @receipt.reference_number = last.reference_number.next
      end
    end
  end

  def account_statement
    @client.update_statement(tenant)
    from = params[:as_at].to_date
    unless @client.transactions.empty?
      from = @client.transactions[0].transaction_date
    end
    end_date = params[:as_at].to_date
    respond_to do |format|
      format.html
      format.pdf do 
        pdf = AccountStatementPdf.new(tenant,@client,logo_path,from,end_date)
        send_data pdf.render, :filename => "#{@client.name} Account Statement as at #{end_date.strftime("%d/%m/%Y")}.pdf",
                    :type => "application/pdf", :disposition => "inline"
      end
    end
  end

  def print_by_date
    @client = Client.find(params[:id])
  end

  def takeon_balances
    @client = Client.find(params[:id])
    # get the last journal
    last = Transaction.last
    @transaction = Transaction.new  
    @transaction.source = "Invoices"
    @transaction.client_id = @client.id

  end

  def save_journal
    @client = Client.find(params[:client_id])
    @transaction = Transaction.new(transaction_params)
    last = Transaction.where(tenant_id: tenant.id).last
    if last.nil?
      @transaction.reference_number = "JNL00001"
    else
      @transaction.reference_number = last.reference_number.next
    end
    @transaction.source = "Invoices"
    @transaction.source_id = 1
    @transaction.user_id = current_user.id
    @transaction.tenant_id = tenant.id
    @transaction.debit = true
    @transaction.journal = true
    if @transaction.save
      redirect_to @client, notice: "Transaction was successfully created."
      exchange_rates = ExchangeRate.order(transaction_date: :asc).where("currency_id = #{@transaction.currency_id} AND transaction_date <= '#{@transaction.transaction_date}'")
      rate = 1
      unless exchange_rates.empty?
        rate = exchange_rates[-1].selling_rate
      end
      @transaction.update(balance: @transaction.amount, rate: rate)
    else
      render :takeon_balances, status: :unprocessable_entity
    end
  end

  def edit_journal
    @client = Client.find(params[:client_id])
    @transaction = Transaction.find(params[:id])
  end

  def update_journal
    @client = Client.find(params[:client_id])
    @transaction = Transaction.find(params[:id])
    prev_amount = @transaction.amount
    prev_date = @transaction.transaction_date
    if @transaction.update(transaction_params)
      user = current_user
      ipaddress = request.remote_ip
      device_name = "#{request.user_agent}"
      activity = "#{user.user_fullname} modified Journal with ID #{@transaction.id}. Amount changed from #{prev_amount} to #{@transaction.amount} and Date changed from #{prev_date} to #{@transaction.transaction_date}"
      user_log(user,activity,ipaddress,device_name)      
      redirect_to @client, notice: "Journal successfully updated"
    else
      render :edit_journal, status: :unprocessable_entity
    end
  end

  def reset_statement
    Transaction.where(client_id: @client.id, journal: false).delete_all
    @client.update_statement(tenant)
    redirect_to @client
  end

  # def account_statement
  #   @client.update_statement
  #   pdf = Prawn::Document.new 
  #   # Start of PDF
  #     pdf.text "#{tenant.company_name}", style: :bold, size: 16
  #     pdf.text "#{tenant.address_1}", style: :normal, size: 11
  #     pdf.text "#{tenant.address_2}", style: :normal, size: 11
  #     pdf.text "#{tenant.location}, #{tenant.city}", style: :normal, size: 11
  #     pdf.text "#{tenant.country}", style: :normal, size: 11
  #     pdf.move_down 20
  #     pdf.text "Statement For:", style: :bold, size: 11
  #     pdf.text "#{@client.name}", style: :normal, size: 10
  #     pdf.text "#{@client.address_1}", style: :normal, size: 10
  #     pdf.text "#{@client.address_2}", style: :normal, size: 10
  #     pdf.text "#{@client.location}, #{@client.city}", style: :normal, size: 10
  #     pdf.text "#{@client.country}", style: :normal, size: 10

  #     pdf.move_down 20
  #     pdf.text "Account Statement as at #{Date.today.strftime("%d/%m/%Y")}", style: :bold, size: 12, align: :center
  #     pdf.move_down 20

  #     data = Array.new(){Array.new()}
  #     data.push ["#","Date","Ref No.","Description","Debit","Credit","Balance"]

  #     pdf.table data,:column_widths => {0=>30,1=>70,2=>80,3=>120,4=>80,5=>80,6=>80},:position => :center,:row_colors => ["FFFFFF","FFFFFF"]
  #     balance = 0
  #     unless @client.transactions.empty?
  #     data = Array.new(){Array.new()}
  #     @client.transactions.each_with_index do |transaction,i|
  #       if transaction.debit?
  #         balance += transaction.amount
  #         data.push ["#{i+=1}",transaction.transaction_date.strftime("%d/%m/%Y"),transaction.reference_number,transaction.description,transaction.amount,"",balance]
  #       else
  #         balance -= transaction.amount
  #         data.push ["#{i+=1}",transaction.transaction_date.strftime("%d/%m/%Y"),transaction.reference_number,transaction.description,"",transaction.amount,balance]
  #       end
  #     end
  #     pdf.table data,:column_widths => {0=>30,1=>70,2=>80,3=>120,4=>80,5=>80,6=>80},:position => :center,:row_colors => ["FFFFFF","FFFFFF"]
  #     end
  #   # End of PDF
  #   send_data(pdf.render, 
  #     filename: "#{@client.name} Statement as at #{Date.today.strftime("%d/%m/%Y")}.pdf",
  #     type: 'application/pdf', disposition: 'inline')   
  # end

  # GET /clients/new
  def new
    @client = Client.new
    @client.tenant_id = current_user.tenant_id
  end

  # GET /clients/1/edit
  def edit
  end

  # POST /clients
  def create
    @client = Client.new(client_params)
    last = tenant.clients.order(client_account_number: :asc)[-1]
    if last.nil?
      @client.client_account_number = "10001"
    else
      @client.client_account_number = last.client_account_number.next
    end
    if @client.save
      redirect_to @client, notice: "Client was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /clients/1
  def update
    if @client.update(client_params)
      redirect_to @client, notice: "Client was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /clients/1
  def destroy
    @client.update_attribute(:active, false)
    redirect_to clients_url, notice: "Client was successfully deleted.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_client
      @client = Client.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def client_params
      params.require(:client).permit(:client_type_id, :industry_id, :currency_id, :name, :trading_name, :client_account_number, :bp_number, :vat_number, :address_1, :address_2, :location, :city, :country, :website, :mobile, :phone, :email, :cp_name, :cp_mobile, :cp_email, :active, :tenant_id, branches_attributes: [:id, :tenant_id, :name, :address_1, :location, :city, :license_option_id, :license_category_id])
    end

    def transaction_params
      params.require(:transaction).permit(:client_id, :transaction_date, :reference_number, :description, :amount, :debit, :user_id, :source, :source_id, :debit, :tenant_id, :currency_id)
    end
end
