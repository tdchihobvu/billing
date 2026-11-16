require "test_helper"

class PaymentTrackingTest < ActiveSupport::TestCase
  setup do
    @invoice = invoices(:one)
    @invoice.update_columns(deleted: false, paid: false, discount: 0)
    @receipt = receipts(:one)
    @receipt.update_columns(currency_id: @invoice.currency_id, client_id: @invoice.client_id, deleted: false, invoice_id: nil, rate: 1)
    @license = @invoice.license
    @license.update_columns(amount: 100, paid: false)
  end

  def pay(amount)
    @receipt.update!(invoice_id: @invoice.id, amount: amount)
    @invoice.reload
  end

  test "a full payment marks the invoice and licence paid immediately" do
    pay(@invoice.total)

    assert @invoice.paid?
    assert @invoice.fully_paid?
    assert @license.reload.paid?
  end

  test "a part payment stays part paid" do
    pay(@invoice.total / 2)

    assert @invoice.partly_paid?
    assert_not @invoice.paid?
  end

  test "an overpaid invoice counts as settled" do
    pay(@invoice.total + 5)

    assert @invoice.overpaid?
    assert @invoice.paid?
  end

  test "voiding a receipt reopens the invoice" do
    pay(@invoice.total)
    @receipt.update!(deleted: true)

    assert_not @invoice.reload.paid?
    assert_equal 0, @invoice.amount_paid
  end

  test "setoffs count towards the balance when the statement is viewed" do
    pay(@invoice.total)
    @receipt.update_column(:receipt_type, "Setoff")
    @invoice.sync_balance

    assert_equal @invoice.total.to_d.round(2), @invoice.reload.amount_paid
  end

  test "a wrong stored figure does not change the balance" do
    pay(@invoice.total)
    @receipt.update_column(:actual_paid, 1.52)
    @invoice.sync_balance

    assert @invoice.reload.paid?
  end

  test "a payment in another currency converts by the receipt's rate" do
    other = currencies(:two)
    @receipt.update_columns(currency_id: other.id, rate: 25, invoice_id: @invoice.id, amount: @invoice.total * 25)

    assert_equal @invoice.total.to_d.round(2), @invoice.total_paid
  end

  test "a discount reduces the total and VAT once" do
    @invoice.update!(discount: 40)
    @invoice.update_balance
    @invoice.update_balance

    assert_equal 40, @invoice.reload.discount_amount
    assert_equal 100, @license.reload.amount
    assert_equal 60, @invoice.sub_total - @invoice.discount_amount
  end

  test "a discount cannot exceed the subtotal" do
    @invoice.discount = 500

    assert_not @invoice.valid?
    assert_includes @invoice.errors[:discount], "cannot be more than the invoice subtotal"
  end
end
