class PopulateSyncReference < ActiveRecord::Migration[7.1]
  def change
  end
  # Receipt.where(sync_reference: nil).each do |receipt|
  #   puts("dealing with #{receipt.reference_number}")
  #   receipt.update_attribute(:sync_reference, "#{receipt.transaction_date.strftime("%y%m%d")}#{receipt.source_reference}")
  # end
end
