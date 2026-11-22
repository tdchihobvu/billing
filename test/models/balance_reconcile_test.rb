require "test_helper"

# Invoice balances must agree with the client's statement (issue 7: settled invoices shown as unpaid).
class BalanceReconcileTest < ActiveSupport::TestCase
  setup do
    @invoice = invoices(:one)
    @invoice.update_columns(deleted: false, paid: false, discount: 0, rate: 1, account_credit: 0)
    @client = @invoice.client
    @client.update_columns(currency_id: @invoice.currency_id)
    Transaction.where(client_id: @client.id).delete_all # the fixture's stray statement line
    @receipt = receipts(:one)
    @receipt.update_columns(currency_id: @invoice.currency_id, client_id: @client.id, deleted: false, invoice_id: nil, rate: 1)
    @invoice.license.update_columns(amount: 100, paid: false)
    @invoice.update_balance
  end

  test "a payment on account settles the client's unpaid invoice" do
    @receipt.update!(amount: @invoice.total)

    @invoice.reload
    assert @invoice.paid?
    assert_equal @invoice.total.to_d.round(2), @invoice.account_credit
    assert_equal 0, @invoice.balance
  end

  test "a part payment on account leaves the rest owing" do
    @receipt.update!(amount: 30)

    @invoice.reload
    assert @invoice.partly_paid?
    assert_equal @invoice.total.to_d - 30, @invoice.balance
  end

  test "voiding a payment on account reopens the invoice" do
    @receipt.update!(amount: @invoice.total)
    @receipt.update!(deleted: true)

    @invoice.reload
    assert_not @invoice.paid?
    assert_equal 0, @invoice.account_credit
  end

  test "a receipt cannot be attached to another client's invoice" do
    @receipt.invoice_id = invoices(:two).id

    assert_not @receipt.valid?
    assert_match "belongs to another client", @receipt.errors[:invoice].join
  end

  test "an old receipt attached to another client's invoice does not pay that invoice" do
    other = invoices(:two)
    @receipt.update_columns(client_id: clients(:two).id, invoice_id: @invoice.id, amount: @invoice.total)

    assert_equal 0, @invoice.total_paid
    assert_not_equal other.client_id, @invoice.client_id
  end

  test "a fully paid invoice gets no account credit" do
    @receipt.update!(invoice_id: @invoice.id, amount: @invoice.total)

    @invoice.reload
    assert @invoice.paid?
    assert_equal 0, @invoice.account_credit
  end
end
