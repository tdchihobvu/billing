class TenantSerializer < ActiveModel::Serializer
  attributes :company_name, :address_1, :address_2, :location, :city, :country, :mobile_1, :phone_1, :phone_2, :sales_email, :website, :banks

  # The same accounts the website prints, for invoices made on devices.
  def banks
    object.banks.active.map do |bank|
      { description: bank.description, bank_name: bank.bank_name, account_name: bank.account_name, account_number: bank.account_number, branch: bank.branch, swift_code: bank.swift_code }
    end
  end
end
