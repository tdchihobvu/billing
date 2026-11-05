class ExchangeRate < ApplicationRecord
  belongs_to :currency
  belongs_to :user

  def update_currency
    currency.update_attribute(:rate, self.selling_rate)
  end

  def self.active_exchange_rate(tenant, transaction_date, frequency)
    transaction_date = transaction_date.to_date

    rate = case frequency.to_s.downcase
           when "daily"
             where(tenant_id: tenant.id)
               .where(transaction_date: transaction_date)
               .order(transaction_date: :desc)
               .first

           when "weekly"
             where(tenant_id: tenant.id)
               .where(transaction_date: transaction_date - 6.days..transaction_date)
               .order(transaction_date: :desc)
               .first

           when "monthly"
             where(tenant_id: tenant.id)
               .where(transaction_date: transaction_date - 1.month + 1.day..transaction_date)
               .order(transaction_date: :desc)
               .first

           when "skip day"
             where(tenant_id: tenant.id)
               .where(transaction_date: transaction_date - 1.day..transaction_date)
               .order(transaction_date: :desc)
               .first
           end

    rate&.selling_rate
  end

  def self.converted_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency)
    last_update = ExchangeRate.order(transaction_date: :desc).where(tenant_id: tenant.id).first
    unless last_update.nil?
      case exchange_rate_update_frequency
      when 'daily'
        end_date = transaction_date.to_date - 1.day
        exchange_rates = ExchangeRate.order(transaction_date: :asc).where("transaction_date >= '#{end_date}'")
        unless exchange_rates.empty?
          rate = 1/exchange_rates[-1].selling_rate
        end
      when 'weekly'
        end_date = transaction_date.to_date - 1.week
        exchange_rates = ExchangeRate.order(transaction_date: :asc).where("transaction_date >= '#{end_date}'")
        unless exchange_rates.empty?
          rate = 1/exchange_rates[-1].selling_rate
        end
      when 'monthly'
        end_date = transaction_date.to_date - 1.month
        exchange_rates = ExchangeRate.order(transaction_date: :asc).where("transaction_date >= '#{end_date}'")
        unless exchange_rates.empty?
          rate = 1/exchange_rates[-1].selling_rate
        end
      when 'skip day'
        end_date = transaction_date.to_date - 2.days
        exchange_rates = ExchangeRate.order(transaction_date: :asc).where("transaction_date >= '#{end_date}'")
        unless exchange_rates.empty?
          rate = 1/exchange_rates[-1].selling_rate
        end
      else
        rate = nil
      end
    end
  end

end
