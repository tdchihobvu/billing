class LicensesController < ApplicationController
  before_action :set_license, only: %i[ show edit update destroy print print_plain assign_vehicles vehicle_discs ]
  # No licence can be printed until Finance and the Manager have approved it.
  before_action :require_approved_license, only: %i[ print print_plain vehicle_discs ]

  # PATCH /licenses/1/vehicles  Chooses which of the client's vehicles this licence covers.
  def assign_vehicles
    ids = Array(params[:vehicle_ids]).reject(&:blank?)
    @license.vehicle_ids = @license.client.vehicles.where(id: ids).pluck(:id)
    @license.touch # phones re-download this licence's vehicles at the next sync
    count = @license.vehicles.size
    note = count > @license.quantity.to_i && @license.quantity.to_i.positive? ? " This is more than the #{@license.quantity} licence(s) invoiced." : ""
    redirect_to license_path(@license, anchor: "vehicles"), notice: "This licence now covers #{count} #{'vehicle'.pluralize(count)}.#{note}", status: :see_other
  end

  # GET /licenses/1/vehicle_discs.pdf  One licence disc page per covered vehicle (or just ?vehicle_id=).
  def vehicle_discs
    vehicles = @license.vehicles.active.ordered
    vehicles = vehicles.where(id: params[:vehicle_id]) if params[:vehicle_id].present?
    if vehicles.empty?
      return redirect_to(license_path(@license, anchor: "vehicles"), alert: "Choose the vehicles this licence covers first.")
    end

    respond_to do |format|
      format.pdf do
        pdf = VehicleDiscPdf.new(@license, vehicles.to_a, logo_path)
        name = vehicles.size == 1 ? vehicles.first.registration_number : "#{@license.client.name} vehicle discs"
        send_data pdf.render, filename: "#{name.parameterize}.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  # GET /licenses
  def index
    # @licenses = License.active.select("invoices.*").joins("LEFT OUTER JOIN invoices ON (licenses.invoice_id = invoices.id AND invoices.deleted = false)")
    respond_to do |format|
      format.html do
        mark_settled_licenses_paid
        scope = License.active.joins(:client, :invoice).where(invoices: { deleted: false, tenant_id: tenant.id })
        if params[:q].present?
          scope = TextSearch.apply(scope, params[:q], %w[clients.name clients.client_account_number invoices.invoice_number])
        end
        scope = scope.where(paid: params[:paid] == "yes") if %w[yes no].include?(params[:paid])
        @count = scope.count
        @per_page = 50
        @page = [params[:page].to_i, 1].max
        @pages = [(@count / @per_page.to_f).ceil, 1].max
        @licenses = scope.preload(:invoice, :license_option, client: :branches).order(:expiry_date).offset((@page - 1) * @per_page).limit(@per_page)
      end
      format.json do
        scope = License.active.joins(:client, :license_option, :invoice).where(invoices: { deleted: false }).preload(:invoice, :license_option, client: :branches)
        columns = [nil, "clients.name",
                   { sort: "licenses.renewal_date", search: "to_char(licenses.renewal_date, 'DD Mon YYYY') || ' to ' || to_char(licenses.expiry_date, 'DD Mon YYYY')" },
                   "license_options.name", "licenses.status", nil]
        vc = view_context
        render_server_side_table(scope, columns: columns) do |license, number|
          [number, ERB::Util.html_escape(license.client.name), license.long_period, ERB::Util.html_escape(license.license_option.name), ERB::Util.html_escape(license.status),
           vc.render(partial: "licenses/row_actions", formats: [:html], locals: { license: license })]
        end
      end
    end
  end

  # GET /licenses/1
  def show
  end

  # GET /licenses/new
  # Generate License: find a client by name or account number, with their current licence.
  def new
    term = params[:search].to_s.strip
    @clients = []
    return if term.length < 2

    @clients = TextSearch.apply(tenant.clients, term, %w[clients.name clients.trading_name clients.client_account_number clients.city clients.location])
                         .order(:name).limit(50).to_a
    # Each client's latest licence, to show its status in the results.
    @latest = License.joins(:invoice).where(client_id: @clients.map(&:id), invoices: { deleted: false })
                     .preload(:license_category).order(expiry_date: :desc).group_by(&:client_id).transform_values(&:first)
  end

  def generate
    @client = tenant.clients.find(params[:client_id])
    # get the last invoice generated
    last_invoice = @client.invoices.active.order('invoice_date Asc').last
    @license = nil
    unless last_invoice.nil?
      # check if the license already exists
      @license = License.find_by(invoice_id: last_invoice.id)
    else
      # generate new license
    end
  end

  def generate_new
    @client = tenant.clients.find(params[:client_id])
    @license = License.new
    @license.client_id = @client.id
  end

  # GET /licenses/1/edit
  def edit
    @client = @license.client
  end

  # POST /licenses
  def create
    @license = License.new(license_params)
    @client = tenant.clients.find(params[:license][:client_id])
    if @license.save
      redirect_to @license, notice: "License was successfully created."
    else
      render :generate_new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /licenses/1
  def update
    if @license.update(license_params)
      redirect_to @license, notice: "License was successfully updated.", status: :see_other
    else
      @client = @license.client
      render :edit, status: :unprocessable_entity
    end
  end

  # def print 
  #   pdf = Prawn::Document.new 
  #   # Start of PDF
  #     pdf.move_down 40
  #     pdf.text "ZIMURA", style: :bold, size: 32, align: :center
  #     pdf.text "LOGO", style: :bold, size: 32, align: :center
  #     pdf.move_down 10
  #     pdf.text "#{tenant.company_name}", style: :normal, size: 22, align: :center
  #     pdf.move_down 20
  #     pdf.text "#{@license.license_category.name} License", style: :bold, size: 18, align: :center
  #     pdf.move_down 5
  #     pdf.text "Valid for the Period #{@license.long_period}", style: :normal, size: 11, align: :center
  #     pdf.move_down 30
  #     pdf.text "#{@license.client.name}", style: :normal, size: 18, align: :center
  #     pdf.move_down 100
  #     pdf.text "QR CODE", style: :bold, size: 32, align: :center
  #     pdf.text "HERE", style: :bold, size: 32, align: :center
  #     pdf.text "The authenticity and validity of this license can be vaildated on", style: :normal, size: 10, align: :center
  #     pdf.text "https://portal.zimura.co.zw/license-validator", style: :normal, size: 10, align: :center
  #     pdf.move_down 200
  #     pdf.stroke_horizontal_rule
  #     pdf.move_down 5
  #     pdf.text "License Generated by #{tenant.company_name} for #{@license.client.name} at #{Date.today.strftime("%d/%m/%y %H:%M")} from Aibes Billing System ver 7.1", style: :normal, size: 8, align: :center
    

  #   # End of PDF
  #   send_data(pdf.render, 
  #     filename: "#{@license.client.name} - #{@license.license_category.name} #{@license.period}.pdf",
  #     type: 'application/pdf', disposition: 'inline')   
  # end

  def print
    respond_to do |format|
      format.html
      format.pdf do 
        pdf = LicensePdf.new(@license,current_user,logo_path)
        send_data pdf.render, :filename => "#{@license.invoice.client.name}.pdf",
                    :type => "application/pdf", :disposition => "inline"
      end
    end    
  end

  def print_plain
    respond_to do |format|
      format.html
      format.pdf do 
        pdf = LicensePlainPdf.new(@license,current_user,logo_path)
        send_data pdf.render, :filename => "#{@license.invoice.client.name}.pdf",
                    :type => "application/pdf", :disposition => "inline"
      end
    end    
  end

  def print_multiple
    @client = tenant.clients.find(params[:client_id])
    @license = @client.licenses.find(params[:id])
    return unless require_approved_license
    @branches = @client.branches
    unless @license.invoice.branches.empty?
      @branches = @license.invoice.branches
    end
  end

  def branch_license
    @license = tenant_licenses.find(params[:license_id])
    return unless require_approved_license
    @branch = @license.client.branches.find(params[:branch_id])
    respond_to do |format|
      format.html
      format.pdf do 
        pdf = BranchLicensePdf.new(@license,@branch,current_user,logo_path)
        send_data pdf.render, :filename => "#{@branch.name}.pdf"#,
                    # :type => "application/pdf", :disposition => "inline"
      end
    end    
  end

  def download_all
    @license = tenant_licenses.find(params[:id])
    return unless require_approved_license
    @client = tenant.clients.find(params[:client])

    respond_to do |format|
      format.html
      format.pdf do 
        pdf = AllBranchesLicensesPdf.new(@license,@client,current_user,logo_path)
        send_data pdf.render, :filename => "#{@client.name.upcase} LICENSES.pdf"
      end
    end 

  end

  # DELETE /licenses/1
  def destroy
    @license.destroy!
    redirect_to licenses_url, notice: "License was successfully destroyed.", status: :see_other
  end

  private
    # Only looks at unpaid licenses whose invoice is settled, not every license.
    def mark_settled_licenses_paid
      License.active.where(paid: false).joins(:invoice).where(invoices: { tenant_id: tenant.id }).where("invoices.invoice_total - invoices.amount_paid < 1").find_each do |license|
        license.update_attribute(:paid, true)
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_license
      @license = tenant_licenses.find(params[:id])
    end

    def tenant_licenses
      License.joins(:invoice).where(invoices: { tenant_id: tenant.id })
    end

    # Returns true when printing may go ahead; otherwise explains why and sends the user back.
    def require_approved_license
      return true if @license.printable?

      message = "This licence can't be printed yet: #{@license.approval_label.downcase}. #{@license.approval_hint}"
      redirect_to license_path(@license), alert: message
      false
    end

    # Only allow a list of trusted parameters through.
    def license_params
      params.require(:license).permit(:client_id, :invoice_id, :amount, :license_category_id, :renewal_date, :expiry_date, :auto_renewal, :license_option_id, :printed, :active, :qr_code, :special_days, :is_special)
    end
end
