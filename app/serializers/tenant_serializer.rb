class TenantSerializer < ActiveModel::Serializer
  # bp_number (TIN) and vat_number let phones print the same company block as the website's PDFs.
  attributes :company_name, :address_1, :address_2, :location, :city, :country, :mobile_1, :phone_1, :phone_2, :sales_email, :website, :bp_number, :vat_number, :banks

  # The same accounts the website prints, for invoices made on devices.
  def banks
    object.banks.active.map do |bank|
      { description: bank.description, bank_name: bank.bank_name, account_name: bank.account_name, account_number: bank.account_number, branch: bank.branch, swift_code: bank.swift_code }
    end
  end
end
