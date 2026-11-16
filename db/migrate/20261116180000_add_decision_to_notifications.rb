# Void requests from phones become decisions (approved or rejected, with who, when and why)
# made on the Void requests page, instead of a link that voided the invoice in one click.
class AddDecisionToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :decision, :string        # approved, rejected
    add_column :notifications, :decided_at, :datetime
    add_column :notifications, :decision_note, :text
    add_index :notifications, %i[processed process_url]
  end
end
